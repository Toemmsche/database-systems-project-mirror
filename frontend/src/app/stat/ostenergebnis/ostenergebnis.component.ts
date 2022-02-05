import {Component, OnDestroy, OnInit} from '@angular/core';
import { Subscription } from 'rxjs';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import {WahlkreisParteiErgebnis} from "../../../model/WahlkreisParteiErgebnis";
import {REST_GET} from "../../../util/ApiService";
import {sortWithSonstige} from "../../../util/ArrayHelper";

@Component({
  selector: 'app-ostenergebnis',
  templateUrl: './ostenergebnis.component.html',
  styleUrls: ['./ostenergebnis.component.scss']
})
export class OstenergebnisComponent implements OnInit, OnDestroy {

  wahl !: number;
  ostenData !: Array<WahlkreisParteiErgebnis>
  ostenConfig = {
    type: 'bar',
    data: {
      labels: [] as Array<string>,
      datasets: [
        {
          label: "Zweitstimmen",
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
            return item.yLabel.toFixed(2) + '%';
          }
        }
      }
    }
  }

  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.ostenData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate() {
    REST_GET(`${this.wahl}/stat/ostenergebnis`)
      .then(response => response.json())
      .then((data: Array<WahlkreisParteiErgebnis>) => {
        data = data.sort(sortWithSonstige);

        // Populate bar chart
        const chartData = this.ostenConfig.data;
        chartData.labels = data.map((result) => result.partei);
        chartData.datasets[0].data = data.map((result) => 100 * result.rel_stimmen);
        chartData.datasets[0].backgroundColor = data.map((result) => '#' +
          result.partei_farbe);
        // Make sure chart is refreshed when new data is available
        this.ostenConfig.data = Object.assign({}, chartData);

        // Save for later
        this.ostenData = data;
      });
  }

  ostenLoaded() {
    return this.ostenData != null && this.ostenData.length > 0;
  }
}
