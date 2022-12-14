import {Component, OnInit, ViewChild} from '@angular/core';
import {FormControl, Validators} from '@angular/forms';
import {SvgKarteComponent} from 'src/app/karte/svg-karte/svg-karte.component';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {Begrenzung} from 'src/model/Begrenzung';
import {Metrik} from 'src/model/Metrik';
import {Rangliste} from 'src/model/Rangliste';
import {REST_GET, REST_POST} from 'src/util/ApiService';
import ParteiErgebnis from "../../../model/ParteiErgebnis";
import {mergeCduCsu} from "../../../util/ArrayHelper";

@Component({
  selector   : 'app-strukturdaten',
  templateUrl: './strukturdaten.component.html',
  styleUrls  : ['./strukturdaten.component.scss']
})
export class StrukturdatenComponent implements OnInit {
  wahl !: number;
  metriken !: Array<Metrik>;
  topNFormControl = new FormControl(10, [Validators.min(1), Validators.max(100), Validators.required]);
  metrikFormControl = new FormControl(undefined, [Validators.required]);
  rangliste !: Array<Rangliste>;
  bData !: Array<Begrenzung>;
  kartenTyp: number = 1;

  private colorNiedrig: string = "ff4081";
  private colorHoch: string = "3f51b5";

  @ViewChild(SvgKarteComponent) karte !: SvgKarteComponent;

  ergebnisseNiedrig !: Array<ParteiErgebnis>;
  ergebnisseHoch !: Array<ParteiErgebnis>;
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
              beginAtZero: true,
              callback: (item: any) => {
                return item + '%';
              }
            }
          }
        ]
      },
      legend: {
        labels: {
          generateLabels: (chart: any) => {
            var data = chart.config.data;

            return data.datasets.map((ds: any, index: number) => ({
              text: ds.label,
              fillStyle: ds.legendColor,
              datasetIndex: index,
              hidden: chart.getDatasetMeta(index).hidden
            })
            );
          }
        },
      },
      tooltips: {
        callbacks: {
          label: (item: any) => {
            return item.yLabel.toFixed(2) + '%';
          }
        }
      }
    }
  }

  constructor(private readonly wahlService: WahlSelectionService) {}

  ngOnInit(): void {
    this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.metriken = [];
      this.rangliste = [];
      this.populateMetriken();
      this.populateBegrenzungen();
    });
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
        const oldValue = this.metrikFormControl?.value;
        this.metriken = data;
        if (oldValue) {
          const selectedValue = data.find(metrik => metrik.metrik == oldValue.metrik);
          if (selectedValue) {
            this.metrikFormControl.setValue(selectedValue);
          } else {
            this.metrikFormControl.reset();
          }
        }
      });
  }

  populateRangliste(): void {
    if (!this.metrikFormControl.valid || !this.topNFormControl.valid) {
      return;
    }
    REST_GET(`${this.wahl}/rangliste/${this.metrikFormControl.value.metrik}`)
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
        if (r.rank <= this.topNFormControl.value) {
          this.karte.colorWahlkreis(r.nummer, this.colorNiedrig);
        } else if (r.rank > this.rangliste.length - this.topNFormControl.value) {
          this.karte.colorWahlkreis(r.nummer, this.colorHoch);
        }
      });
    }
  }

  async populateData() {
    const count = this.rangliste.length;
    const lowestBody = this.rangliste.filter(r => r.rank <= this.topNFormControl.value).map(r => r.nummer);
    const highestBody = this.rangliste.filter(r => r.rank > count - this.topNFormControl.value).map(r => r.nummer);

    let lowestData: Array<ParteiErgebnis> = await REST_POST(`${this.wahl}/zweitstimmen_aggregiert`, lowestBody)
      .then(response => response.json());
    let highestData: Array<ParteiErgebnis> = await REST_POST(`${this.wahl}/zweitstimmen_aggregiert`, highestBody)
      .then(response => response.json());

    // Aggregate CSU / CDU
    lowestData = mergeCduCsu(lowestData);
    highestData = mergeCduCsu(highestData);

    // Sort by party and allign
    lowestData.sort((a, b) => a.partei.localeCompare(b.partei));
    highestData.sort((a, b) => a.partei.localeCompare(b.partei));

    // Populate bar chart
    const chartDataVergleich = this.ergebnisseVergleichConfig.data;
    chartDataVergleich.labels = lowestData.map((result) => result.partei);
    chartDataVergleich.datasets[0].data = lowestData.map((result) => result.rel_stimmen * 100);
    chartDataVergleich.datasets[0].backgroundColor = lowestData.map((result) => '#' +
      result.partei_farbe);
    chartDataVergleich.datasets[1].data = highestData.map((result) => result.rel_stimmen * 100);
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
    if (this.rangliste && this.rangliste.length > 0) {
      const wahlkreis = this.rangliste.find(r => r.nummer == b.wk_nummer);
      return `${def} ${this.metrikFormControl.value.displayName}: ${wahlkreis!.metrik_wert}`;
    }
    return `${b.wk_nummer} - ${b.wk_name}`;
  }
}
