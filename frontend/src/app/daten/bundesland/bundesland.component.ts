import {Component, Input, OnInit} from "@angular/core";
import {BundeslandParteiErgebnis} from "../../../model/BundeslandParteiErgebnis";
import {Subscription} from "rxjs";
import {ActivatedRoute} from "@angular/router";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util/ApiService";
import {sortWithSameSorting, sortWithSonstige} from "../../../util/ArrayHelper";
import Bundesland from "../../../model/Bundesland";

@Component({
  selector   : "app-bundesland",
  templateUrl: "./bundesland.component.html",
  styleUrls  : ["./bundesland.component.scss"]
})
export class BundeslandComponent implements OnInit {

  wahl !: number;

  @Input()
  bl_kuerzel !: string;

  bundesland !: Bundesland;

  zweitstimmenergebnisse !: Array<BundeslandParteiErgebnis>;
  zweitstimmenergebnissePrev !: Array<BundeslandParteiErgebnis>;
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
          hidden         : true,
          label          : "Zweitstimmen (Vorperiode)",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }
      ]
    },
    options: {
      scales  : {
        yAxes: [
          {
            ticks: {
              beginAtZero: true,
              callback   : (item: any) => {
                return item + "%";
              }
            }
          }
        ]
      },
      legend  : {
        display: false
      },
      tooltips: {
        callbacks: {
          label: (item: any) => {
            let diffString = "";
            if (item.datasetIndex ==
              0 &&
              this.zweitstimmenergebnissePrev &&
              this.zweitstimmenergebnissePrev.length >
              0) {
              const diff = 100 *
                (this.zweitstimmenergebnisse[item.index].rel_stimmen -
                  this.zweitstimmenergebnissePrev[item.index].rel_stimmen);
              diffString = `(${diff > 0 ? "+" : ""}${diff.toFixed(2)}%) `
            }
            const abs = item.datasetIndex == 0 ?
              this.zweitstimmenergebnisse[item.index].abs_stimmen :
              this.zweitstimmenergebnissePrev[item.index].abs_stimmen;
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
      this.zweitstimmenergebnisse = [];
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    this.bl_kuerzel = (<string>this.route.snapshot.paramMap.get("bundesland"));
    this.populate();
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  async populate(): Promise<void> {
    REST_GET(`${this.wahl}/bundesland/${this.bl_kuerzel}`)
      .then(response => response.json())
      .then((data: Bundesland) => {
        this.bundesland = data;
      });

    REST_GET(`${this.wahl}/bundesland/${this.bl_kuerzel}/stimmen`)
      .then(response => response.json())
      .then(async (data: Array<BundeslandParteiErgebnis>) => {
        data = data.sort(sortWithSonstige);

        // Populate bar chart
        this.populateBarChartData(data, this.zweitstimmenConfig, 0);

        if (this.wahl > 19) {
          await REST_GET(`${this.wahl - 1}/bundesland/${this.bl_kuerzel}/stimmen`)
            .then(response => response.json())
            .then((dataPrev: Array<BundeslandParteiErgebnis>) => {
              // Insert missing parties
              data
                .filter(pe => dataPrev.findIndex(pePrev => pe.partei == pePrev.partei) == -1)
                .forEach(pe => {
                  dataPrev.push({
                    partei      : pe.partei,
                    partei_farbe: pe.partei_farbe,
                    abs_stimmen : 0,
                    rel_stimmen : 0,
                    wahl        : this.wahl - 1,
                    bl_kuerzel  : pe.bl_kuerzel
                  });
                });
              dataPrev = dataPrev.sort(sortWithSameSorting(data));
              this.populateBarChartData(dataPrev, this.zweitstimmenConfig, 1, 99);

              // Save for later
              this.zweitstimmenergebnissePrev = dataPrev;
            });
        } else {
          // Hide bars from previous election
          this.hideBarChartData(this.zweitstimmenConfig, 1);
          this.zweitstimmenergebnissePrev = [];
        }

        // Save for later
        this.zweitstimmenergebnisse = data;
      });
  }


  private populateBarChartData(data: Array<BundeslandParteiErgebnis>,
                               config: any,
                               index: number,
                               alpha: number = 255): void {
    const alphaSuffix = (alpha < 16 ? "0" : "") + alpha.toString(16);
    // Populate bar chart
    const chartData = config.data;
    chartData.labels = data.map((result) => result.partei);
    chartData.datasets[index].data = data.map((result) => 100 * result.rel_stimmen);
    chartData.datasets[index].backgroundColor = data.map((result) => "#" +
      result.partei_farbe + alphaSuffix);
    chartData.datasets[index].hidden = false;
    config.options.legend.display = true;

    config.data = Object.assign({}, chartData);
  }

  private hideBarChartData(config: any, index: number): void {
    // Populate bar chart
    const chartData = config.data;
    chartData.datasets[index].data = [];
    chartData.datasets[index].hidden = true;
    config.options.legend.display = false;

    config.data = Object.assign({}, chartData);
  }

  bundeslandLoaded(): boolean {
    return this.bl_kuerzel != null &&
      this.zweitstimmenergebnisse != null &&
      this.zweitstimmenergebnisse.length > 0;
  }
}
