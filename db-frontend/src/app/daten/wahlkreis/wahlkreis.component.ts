import {Component, Input, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util";
import {MDB} from "../../../model/MDB";
import {Wahlkreis} from "../../../model/Walhkreis";
import {WahlkreisResult} from "../../../model/WahlkreisResult";

@Component({
  selector: 'app-wahlkreis',
  templateUrl: './wahlkreis.component.html',
  styleUrls: ['./wahlkreis.component.scss']
})
export class WahlkreisComponent implements OnInit {

  @Input()
  nummer !: number;

  wahlkreis !: Wahlkreis;
  results !: Array<WahlkreisResult>
  resultsConfig = {
    type: 'bar',
    data: {
      labels: [] as Array<string>,
      datasets: [
        {
          label: "Erststimmen",
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

  constructor(private route: ActivatedRoute) {
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.populate();
  }

  populate(): void {
    REST_GET(`20/wahlkreis/${this.nummer}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
      });
    REST_GET(`20/wahlkreis/${this.nummer}/results`)
      .then(response => response.json())
      .then((data: Array<WahlkreisResult>) => {
        data = data.sort((a, b) => {
          if (a.partei == 'Sonstige') {
            return 1;
          } else if (b.partei == 'Sonstige') {
            return -1;
          }
          return b.abs_stimmen - a.abs_stimmen;
        });
        // Populate bar chart
        const chartData = this.resultsConfig.data;
        chartData.labels = data.map((result) => result.partei);
        chartData.datasets[0].data = data.map((result) => result.abs_stimmen);
        chartData.datasets[0].backgroundColor = data.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.results = data;
      });


  }

  wahlkreisLoaded(): boolean {
    return this.wahlkreis != null && this.results != null &&
      this.resultsConfig.data.labels.length > 0;
  }

}
