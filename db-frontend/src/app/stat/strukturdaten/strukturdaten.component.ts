import { Component, OnInit, ViewChild } from '@angular/core';
import { FormControl, Validators } from '@angular/forms';
import { SvgKarteComponent } from 'src/app/karte/svg-karte/svg-karte.component';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import { Begrenzung } from 'src/model/Begrenzung';
import { Metrik } from 'src/model/Metrik';
import { ParteiErgebnis } from 'src/model/ParteiErgebnis';
import { Rangliste } from 'src/model/Rangliste';
import { REST_GET, REST_POST } from 'src/util/ApiService';
import { groupBy } from 'src/util/ArrayHelper';

@Component({
  selector: 'app-strukturdaten',
  templateUrl: './strukturdaten.component.html',
  styleUrls: ['./strukturdaten.component.scss']
})
export class StrukturdatenComponent implements OnInit {
  wahl !: number;
  metriken !: Array<Metrik>;
  topN = new FormControl(10, [Validators.min(1), Validators.max(20), Validators.required]);
  metrik = new FormControl(undefined, [Validators.required]);
  rangliste !: Array<Rangliste>;
  bData !: Array<Begrenzung>;
  @ViewChild(SvgKarteComponent) karte !: SvgKarteComponent;

  ergebnisseNiedrig !: Array<ParteiErgebnis>;
  ergebnisseNiedrigConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }
      ]
    },
    options: {
      scales: {
        yAxes: [
          {
            ticks: {
              beginAtZero: true
            }
          }
        ]
      }
    }
  }

  ergebnisseHoch !: Array<ParteiErgebnis>;
  ergebnisseHochConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }
      ]
    },
    options: {
      scales: {
        yAxes: [
          {
            ticks: {
              beginAtZero: true
            }
          }
        ]
      }
    }
  }

  constructor(wahlService: WahlSelectionService) {
    this.wahl = wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = wahlService.getWahlNumber(selection);
      this.metriken = [];
      this.populateMetriken();
      this.populateBegrenzungen();
    });
  }

  ngOnInit(): void {
    this.populateBegrenzungen();
    this.populateMetriken();
  }

  populateBegrenzungen(): void {
    REST_GET(`${this.wahl}/karte`)
      .then(response => response.json())
      .then((data: Array<Begrenzung>) => {
        this.bData = data;
        this.ready();
      });
  }

  ready(): void {
    this.populateRangliste();
  }

  populateMetriken(): void {
    REST_GET(`${this.wahl}/rangliste`)
      .then(response => response.json())
      .then((data: Array<Metrik>) => {
        this.metriken = data;
      });
  }

  populateRangliste(): void {
    if (!this.metrik.valid || !this.topN.valid) {
      return;
    }
    REST_GET(`${this.wahl}/rangliste/${this.metrik.value}`)
      .then(response => response.json())
      .then((data: Array<Rangliste>) => {
        this.rangliste = data;
        this.updateMap();
        this.populateData();
      });
  }

  updateMap() {
    this.karte.resetColors();
    const maxAbsolute: number = this.rangliste.reduce((prev, r) => Math.max(prev, r.metrik_wert), 0);
    this.rangliste.forEach(r => {
      const alpha = Math.round(r.metrik_wert * 255 / maxAbsolute);
      const color = '3f51b5' + (alpha < 16 ? '0' : '') + alpha.toString(16);
      this.karte.colorWahlkreis(r.nummer, color);
    });
  }

  populateData(): void {
    const count = this.rangliste.length;
    const body = this.rangliste.filter(r => r.rank <= this.topN.value || r.rank > count - this.topN.value).map(r => r.nummer);
    const lowest = new Set(this.rangliste.filter(r => r.rank <= this.topN.value).map(r => r.nummer));
    const highest = new Set(this.rangliste.filter(r => r.rank > count - this.topN.value).map(r => r.nummer));
    const groupByMergeCduCsu = (result: ParteiErgebnis) => result.partei == 'CSU' || result.partei == 'CDU' ? 'CDU/CSU' : result.partei;
    REST_POST(`${this.wahl}/zweitstimmen`, body)
      .then(response => response.json())
      .then((data: Array<ParteiErgebnis>) => {
        const groupsLowest = groupBy(data.filter(result => lowest.has(result.wk_nummer)), groupByMergeCduCsu);
        let aggregatedDataLowest = new Array<ParteiErgebnis>(groupsLowest.size);
        let index = 0;
        groupsLowest.forEach((value, key) => {
          const first = value[0];
          const abs_stimmen = value.reduce((prev, curr) => prev + curr.abs_stimmen, 0);
          const color = key == 'CDU/CSU' ? '000000' : first.partei_farbe;
          aggregatedDataLowest[index++] = {partei: key, abs_stimmen: abs_stimmen, partei_farbe: color, stimmentyp: 2, wahl: first.wahl, wk_nummer: first.wk_nummer};
        });
        aggregatedDataLowest = aggregatedDataLowest.sort((a, b) => {
          if (a.partei == 'Sonstige') {
            return 1;
          } else if (b.partei == 'Sonstige') {
            return -1;
          }
          return b.abs_stimmen - a.abs_stimmen;
        });

        // Populate bar chart
        const chartDataLowest = this.ergebnisseNiedrigConfig.data;
        chartDataLowest.labels = aggregatedDataLowest.map((result) => result.partei);
        chartDataLowest.datasets[0].data = aggregatedDataLowest.map((result) => result.abs_stimmen);
        chartDataLowest.datasets[0].backgroundColor = aggregatedDataLowest.map((result) => '#' +
          result.partei_farbe);

        this.ergebnisseNiedrigConfig.data = Object.assign({}, chartDataLowest);

        // Save for later
        this.ergebnisseNiedrig = aggregatedDataLowest;

        const groupsHighest = groupBy(data.filter(result => highest.has(result.wk_nummer)), groupByMergeCduCsu);
        let aggregatedDataHighest = new Array<ParteiErgebnis>(groupsHighest.size);
        index = 0;
        groupsHighest.forEach((value, key) => {
          const first = value[0];
          const abs_stimmen = value.reduce((prev, curr) => prev + curr.abs_stimmen, 0);
          const color = key == 'CDU/CSU' ? '000000' : first.partei_farbe;
          aggregatedDataHighest[index++] = {partei: key, abs_stimmen: abs_stimmen, partei_farbe: color, stimmentyp: 2, wahl: first.wahl, wk_nummer: first.wk_nummer};
        })
        aggregatedDataHighest = aggregatedDataHighest.sort((a, b) => {
          if (a.partei == 'Sonstige') {
            return 1;
          } else if (b.partei == 'Sonstige') {
            return -1;
          }
          return b.abs_stimmen - a.abs_stimmen;
        });

        // Populate bar chart
        const chartDataHighest= this.ergebnisseHochConfig.data;
        chartDataHighest.labels = aggregatedDataHighest.map((result) => result.partei);
        chartDataHighest.datasets[0].data = aggregatedDataHighest.map((result) => result.abs_stimmen);
        chartDataHighest.datasets[0].backgroundColor = aggregatedDataHighest.map((result) => '#' +
          result.partei_farbe);

        this.ergebnisseHochConfig.data = Object.assign({}, chartDataHighest);

        // Save for later
        this.ergebnisseHoch = aggregatedDataHighest;
      });
  }

  bDataLoaded() {
    return this.bData != null && this.bData.length > 0;
  }

  ranglisteLoaded(): boolean {
    return this.rangliste != null && this.rangliste.length > 0;
  }

  stimmenLoaded(): boolean {
    return this.ergebnisseNiedrig != null &&
      this.ergebnisseNiedrig.length > 0;
  }
}
