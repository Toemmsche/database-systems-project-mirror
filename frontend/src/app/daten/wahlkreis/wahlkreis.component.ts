import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util/ApiService";
import {Wahlkreis} from "../../../model/Walhkreis";
import {ParteiErgebnis} from "../../../model/ParteiErgebnis";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {sortWithSonstige, sortWithSameSorting} from "../../../util/ArrayHelper";
import ServerError from "../../../util/ServerError";
import { Subscription } from 'rxjs';

@Component({
  selector   : "app-wahlkreis",
  templateUrl: "./wahlkreis.component.html",
  styleUrls  : ["./wahlkreis.component.scss"]
})
export class WahlkreisComponent implements OnInit, OnDestroy {

  @Input()
  nummer !: number;
  wahl !: number;
  useEinzelstimmen: boolean = false;
  wahlkreis !: Wahlkreis;

  erststimmenergebnisse !: Array<ParteiErgebnis>;
  erststimmenergebnissePrev !: Array<ParteiErgebnis>;
  erststimmenConfig = {
    type   : "bar",
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Erststimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        },
        {
          label: "Erststimmen (Vorperiode)",
          borderWidth: 1,
          data: [] as Array<number>,
          backgroundColor: [] as Array<string>,
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
      tooltips: {
        callbacks: {
          label: (item: any) => {
            let diffString = '';
            if (item.datasetIndex == 0 && this.erststimmenergebnissePrev && this.erststimmenergebnissePrev.length > 0) {
              const diff = 100 * (this.erststimmenergebnisse[item.index].rel_stimmen - this.erststimmenergebnissePrev[item.index].rel_stimmen);
              diffString = `(${diff > 0 ? '+' : ''}${diff.toFixed(2)}%) `;
            }
            const abs = item.datasetIndex == 0 ? this.erststimmenergebnisse[item.index].abs_stimmen : this.erststimmenergebnissePrev[item.index].abs_stimmen;
            return `${item.yLabel.toFixed(2)}% ${diffString}(${abs} Stimmen)`;
          }
        }
      }
    }
  }

  zweitstimmenergebnisse !: Array<ParteiErgebnis>;
  zweitstimmenergebnissePrev !: Array<ParteiErgebnis>;
  zweitstimmenConfig = {
    type   : "bar",
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        },
        {
          hidden: true,
          label: "Zweitstimmen (Vorperiode)",
          borderWidth: 1,
          data: [] as Array<number>,
          backgroundColor: [] as Array<string>,
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
        display: false
      },
      tooltips: {
        callbacks: {
          label: (item: any) => {
            let diffString = '';
            if (item.datasetIndex == 0 && this.zweitstimmenergebnissePrev && this.zweitstimmenergebnissePrev.length > 0) {
              const diff = 100 * (this.zweitstimmenergebnisse[item.index].rel_stimmen - this.zweitstimmenergebnissePrev[item.index].rel_stimmen);
              diffString = `(${diff > 0 ? '+' : ''}${diff.toFixed(2)}%) `
            }
            const abs = item.datasetIndex == 0 ? this.zweitstimmenergebnisse[item.index].abs_stimmen : this.zweitstimmenergebnissePrev[item.index].abs_stimmen;
            return `${item.yLabel.toFixed(2)}% ${diffString}(${abs} Stimmen)`;
          }
        }
      }
    }
  }
  wahlSubscription !: Subscription;

  constructor(
    private route: ActivatedRoute,
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    this.wahlSubscription = wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.erststimmenergebnisse = [];
      this.zweitstimmenergebnisse = [];
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get("nummer"));
    this.populate();
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  async populate(): Promise<void> {
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
      })
      .catch((error) => {
      if (error instanceof ServerError) {
        window.alert("Einzelstimmen liegen nicht vor");
        // Simulate toggle back
        this.useEinzelstimmen = false;
        this.onEinzelstimmenToggleChanged();
      }
    });

    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}/stimmen${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
      .then(response => response.json())
      .then(async (data: Array<ParteiErgebnis>) => {
        data = data.sort(sortWithSonstige);

        // Populate bar chart
        const esData = data.filter(pe => pe.stimmentyp == 1);
        this.populateBarChartData(esData, this.erststimmenConfig, 0);

        // Populate bar chart
        const zsData = data.filter(pe => pe.stimmentyp == 2);
        this.populateBarChartData(zsData, this.zweitstimmenConfig, 0);

        if (this.wahl > 19) {
          await REST_GET(`${this.wahl - 1}/wahlkreis/${this.nummer}/stimmen${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
            .then(response => response.json())
            .then((data: Array<ParteiErgebnis>) => {
              // Populate bar chart
              let esDataPrev = data.filter(pe => pe.stimmentyp == 1);
              // Insert missing parties
              esData.filter(pe => esDataPrev.findIndex(pePrev => pe.partei == pePrev.partei) == -1).forEach(pe => {
                esDataPrev.push({partei: pe.partei, partei_farbe: pe.partei_farbe, abs_stimmen: 0, rel_stimmen: 0, stimmentyp: 1, wahl: this.wahl - 1, wk_nummer: pe.wk_nummer});
              });
              esDataPrev = esDataPrev.sort(sortWithSameSorting(esData));
              this.populateBarChartData(esDataPrev, this.erststimmenConfig, 1, 99);

              // Populate bar chart
              let zsDataPrev = data.filter(pe => pe.stimmentyp == 2);
              // Insert missing parties
              zsData.filter(pe => zsDataPrev.findIndex(pePrev => pe.partei == pePrev.partei) == -1).forEach(pe => {
                zsDataPrev.push({partei: pe.partei, partei_farbe: pe.partei_farbe, abs_stimmen: 0, rel_stimmen: 0, stimmentyp: 2, wahl: this.wahl - 1, wk_nummer: pe.wk_nummer});
              });
              zsDataPrev = zsDataPrev.sort(sortWithSameSorting(zsData));
              this.populateBarChartData(zsDataPrev, this.zweitstimmenConfig, 1, 99);

              // Save for later
              this.erststimmenergebnissePrev = esDataPrev;
              this.zweitstimmenergebnissePrev = zsDataPrev;
          });
        } else {
          // Hide bars from previous election
          this.hideBarChartData(this.erststimmenConfig, 1);
          this.hideBarChartData(this.zweitstimmenConfig, 1);
          this.erststimmenergebnissePrev = [];
          this.zweitstimmenergebnissePrev = [];
        }

        // Save for later
        this.erststimmenergebnisse = esData;
        this.zweitstimmenergebnisse = zsData;
      });
  }

  private populateBarChartData(data: Array<ParteiErgebnis>, config: any, index: number, alpha: number = 255): void {
    const alphaSuffix = (alpha < 16 ? '0' : '') + alpha.toString(16);
    // Populate bar chart
    const chartData = config.data;
    chartData.labels = data.map((result) => result.partei);
    chartData.datasets[index].data = data.map((result) => 100 * result.rel_stimmen);
    chartData.datasets[index].backgroundColor = data.map((result) => "#" +
      result.partei_farbe + alphaSuffix);
    chartData.datasets[index].hidden = false;
    config.options.legend.display = true;

    data = Object.assign({}, chartData);
  }

  private hideBarChartData(config: any, index: number): void {
    // Populate bar chart
    const chartData = config.data;
    chartData.datasets[index].data = [];
    chartData.datasets[index].hidden = true;
    config.options.legend.display = false;

    config.data = Object.assign({}, chartData);
  }

  wahlkreisLoaded(): boolean {
    return this.wahlkreis != null &&
      this.erststimmenergebnisse != null &&
      this.erststimmenergebnisse.length > 0 &&
      this.zweitstimmenergebnisse != null &&
      this.zweitstimmenergebnisse.length > 0;
  }

  onEinzelstimmenToggleChanged() {
    this.erststimmenergebnisse = [];
    this.zweitstimmenergebnisse = [];
    this.ngOnInit();
  }
}
