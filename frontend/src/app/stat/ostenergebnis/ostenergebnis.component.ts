import {Component, OnDestroy, OnInit} from "@angular/core";
import {Subscription} from "rxjs";
import {WahlSelectionService} from "src/app/service/wahl-selection.service";
import {REST_GET} from "../../../util/ApiService";
import {mergeCduCsu} from "../../../util/ArrayHelper";
import OstenParteiErgebnis from "../../../model/OstenParteiErgebnis";
import ParteiErgebnis from "../../../model/ParteiErgebnis";

@Component({
  selector   : "app-ostenergebnis",
  templateUrl: "./ostenergebnis.component.html",
  styleUrls  : ["./ostenergebnis.component.scss"]
})
export class OstenergebnisComponent implements OnInit, OnDestroy {

  wahl !: number;
  ostWestData !: Array<OstenParteiErgebnis>
  ostWestConfig = {
    type   : "bar",
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen (Osten)",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }, {
          label          : "Zweitstimmen (Westen)",
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
      tooltips: {
        callbacks: {
          label: (item: any) => {
            return item.yLabel.toFixed(2) + "%";
          }
        }
      }
    }
  }

  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {
  }

  ngOnInit(): void {
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.ostWestData = [];
      this.populate();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate() {
    REST_GET(`${this.wahl}/stat/ostenergebnis`)
      .then(response => response.json())
      .then((data: Array<OstenParteiErgebnis>) => {

        const sorter = (a: ParteiErgebnis, b: ParteiErgebnis) => a.partei.localeCompare(b.partei);
        const ostenFiltered = mergeCduCsu(data.filter(pe => pe.ist_osten)).sort(sorter);
        const westenFiltered = mergeCduCsu(data.filter(pe => !pe.ist_osten)).sort(sorter);

        const chartData = this.ostWestConfig.data;
        chartData.labels = ostenFiltered.map((result) => result.partei);
        chartData.datasets[0].data = ostenFiltered.map((result) => 100 * result.rel_stimmen);
        chartData.datasets[0].backgroundColor = ostenFiltered.map((result) => "#" +
          result.partei_farbe);
        chartData.datasets[1].data = westenFiltered.map((result) => 100 * result.rel_stimmen);
        chartData.datasets[1].backgroundColor = westenFiltered.map((result) => "#" +
          result.partei_farbe);

        this.ostWestConfig.data = Object.assign({}, chartData);
        this.ostWestData = data;
      });
  }

  ostenLoaded() {
    return this.ostWestData != null && this.ostWestData.length > 0;
  }
}
