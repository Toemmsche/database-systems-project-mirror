import {Component, OnInit} from '@angular/core';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import {ParteiErgebnis} from "../../../model/ParteiErgebnis";
import {REST_GET} from "../../../util";

@Component({
  selector: 'app-ostenergebnis',
  templateUrl: './ostenergebnis.component.html',
  styleUrls: ['./ostenergebnis.component.scss']
})
export class OstenergebnisComponent implements OnInit {

  wahl !: number;
  ostenData !: Array<ParteiErgebnis>
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
              beginAtZero: true
            }
          }
        ]
      }
    }
  }

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.ostenData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  populate() {
    REST_GET(`${this.wahl}/stat/ostenergebnis`)
      .then(response => response.json())
      .then((data: Array<ParteiErgebnis>) => {
        data = data.sort((a, b) => {
          if (a.partei == 'Sonstige') {
            return 1;
          } else if (b.partei == 'Sonstige') {
            return -1;
          }
          return b.abs_stimmen - a.abs_stimmen;
        });

        // Populate bar chart
        const chartData = this.ostenConfig.data;
        chartData.labels = data.map((result) => result.partei);
        chartData.datasets[0].data = data.map((result) => result.abs_stimmen);
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
