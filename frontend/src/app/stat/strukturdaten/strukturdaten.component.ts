import {Component, OnInit, ViewChild} from '@angular/core';
import {FormControl, Validators} from '@angular/forms';
import {SvgKarteComponent} from 'src/app/karte/svg-karte/svg-karte.component';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {Begrenzung} from 'src/model/Begrenzung';
import {Metrik} from 'src/model/Metrik';
import {Rangliste} from 'src/model/Rangliste';
import {REST_GET, REST_POST} from 'src/util/ApiService';
import {ParteiErgebnisVergleich} from "../../../model/ParteiErgebnisVergleich";

@Component({
  selector   : 'app-strukturdaten',
  templateUrl: './strukturdaten.component.html',
  styleUrls  : ['./strukturdaten.component.scss']
})
export class StrukturdatenComponent implements OnInit {
  wahl !: number;
  metriken !: Array<Metrik>;
  topN = new FormControl(10, [Validators.min(1), Validators.max(20), Validators.required]);
  metrik = new FormControl(undefined, [Validators.required]);
  rangliste !: Array<Rangliste>;
  bData !: Array<Begrenzung>;
  kartenTyp: number = 1;

  private colorNiedrig: string = "ff4081";
  private colorHoch: string = "3f51b5";

  @ViewChild(SvgKarteComponent) karte !: SvgKarteComponent;

  ergebnisseNiedrig !: Array<ParteiErgebnisVergleich>;
  ergebnisseHoch !: Array<ParteiErgebnisVergleich>;
  ergebnisseVergleichConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmenanteil (Niedrig)",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
          legendColor    : '#' + this.colorNiedrig
        },
        {
          label          : "Zweitstimmenanteil (Hoch)",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
          legendColor    : '#' + this.colorHoch
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
      },
      legend: {
        labels: {
          generateLabels: function (chart: any) {
            var data = chart.config.data;

            return data.datasets.map((ds: any, index: number) => ({
              text: ds.label,
              fillStyle: ds.legendColor,
              datasetIndex: index,
              hidden: chart.getDatasetMeta(index).hidden
            })
            );
          }
        }
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
        this.ergebnisseHoch = [];
        this.ergebnisseNiedrig = [];
        const oldValue = this.metrik?.value;
        this.metriken = data;
        if (oldValue) {
          const selectedValue = data.find(metrik => metrik.metrik == oldValue.metrik);
          if (selectedValue) {
            this.metrik.setValue(selectedValue);
          } else {
            this.metrik.reset();
          }
        }
      });
  }

  populateRangliste(): void {
    if (!this.metrik.valid || !this.topN.valid) {
      return;
    }
    REST_GET(`${this.wahl}/rangliste/${this.metrik.value.metrik}`)
      .then(response => response.json())
      .then((data: Array<Rangliste>) => {
        this.rangliste = data;
        this.updateMap();
        this.populateData();
      });
  }

  updateMap() {
    this.karte.resetColors();
    if (this.kartenTyp == 1) {
      const maxAbsolute: number = this.rangliste.reduce((prev, r) => Math.max(prev, r.metrik_wert), 0);
      this.rangliste.forEach(r => {
        const alpha = Math.round(r.metrik_wert * 255 / maxAbsolute);
        const color = '3f51b5' + (alpha < 16 ? '0' : '') + alpha.toString(16);
        this.karte.colorWahlkreis(r.nummer, color);
      });
    } else if (this.kartenTyp == 2) {
      this.rangliste.forEach(r => {
        if (r.rank <= this.topN.value) {
          this.karte.colorWahlkreis(r.nummer, this.colorNiedrig);
        } else if (r.rank > this.rangliste.length - this.topN.value) {
          this.karte.colorWahlkreis(r.nummer, this.colorHoch);
        }
      });
    }
  }

  async populateData() {
    const count = this.rangliste.length;
    const lowestBody = this.rangliste.filter(r => r.rank <= this.topN.value).map(r => r.nummer);
    const highestBody = this.rangliste.filter(r => r.rank > count - this.topN.value).map(r => r.nummer);

    let lowestData: Array<ParteiErgebnisVergleich> = await REST_POST(`${this.wahl}/zweitstimmen_aggregiert`, lowestBody)
      .then(response => response.json());
    let highestData: Array<ParteiErgebnisVergleich> = await REST_POST(`${this.wahl}/zweitstimmen_aggregiert`, highestBody)
      .then(response => response.json());

    const mergeCduCsu = (data: Array<ParteiErgebnisVergleich>) => {
      const onlyCduCsu = data.filter(pe => pe.partei === 'CSU' || pe.partei === 'CDU');
      const merged = new ParteiErgebnisVergleich(this.wahl, "UNION", '000000',
        onlyCduCsu
          .map(pe => pe.abs_stimmen)
          .reduce((a, b) => a + b),
        onlyCduCsu
          .map(pe => pe.rel_stimmen)
          .reduce((a, b) => a + b));
      data.push(merged);
      return data.filter(pe => pe.partei !== 'CSU' && pe.partei !== 'CDU');
    }

    // Aggregate CSU / CDU
    lowestData = mergeCduCsu(lowestData);
    highestData = mergeCduCsu(highestData);

    // Sort by party and allign
    lowestData.sort((a, b) => a.partei.localeCompare(b.partei));
    highestData.sort((a, b) => a.partei.localeCompare(b.partei));


    // Populate bar chart
    const chartDataVergleich = this.ergebnisseVergleichConfig.data;
    chartDataVergleich.labels = lowestData.map((result) => result.partei);
    chartDataVergleich.datasets[0].data = lowestData.map((result) => result.rel_stimmen);
    chartDataVergleich.datasets[0].backgroundColor = lowestData.map((result) => '#' +
      result.partei_farbe);
    chartDataVergleich.datasets[1].data = highestData.map((result) => result.rel_stimmen);
    chartDataVergleich.datasets[1].backgroundColor = highestData.map((result) => '#' +
      result.partei_farbe);

    this.ergebnisseVergleichConfig.data = Object.assign({}, chartDataVergleich);
    this.ergebnisseNiedrig = lowestData;
    this.ergebnisseHoch = highestData;
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

  onKartenTypChange() {
    this.updateMap();
  }

  getTooltipText(b: Begrenzung): string {
    const def = `${b.wk_nummer} - ${b.wk_name}`;
    if (this.rangliste) {
      const wahlkreis = this.rangliste.find(r => r.nummer == b.wk_nummer);
      return `${def} ${this.metrik.value.displayName}: ${wahlkreis!.metrik_wert}`;
    }
    return `${b.wk_nummer} - ${b.wk_name}`;
  }
}
