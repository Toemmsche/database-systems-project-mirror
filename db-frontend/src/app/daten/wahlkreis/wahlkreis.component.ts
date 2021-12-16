import {Component, Input, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util";
import {Wahlkreis} from "../../../model/Walhkreis";
import {ParteiErgebnis} from "../../../model/ParteiErgebnis";
import {WahlSelectionService} from "../../service/wahl-selection.service";

@Component({
  selector: 'app-wahlkreis',
  templateUrl: './wahlkreis.component.html',
  styleUrls: ['./wahlkreis.component.scss']
})
export class WahlkreisComponent implements OnInit {

  @Input()
  nummer !: number;
  wahl !: number;

  wahlkreis !: Wahlkreis;
  results !: Array<ParteiErgebnis>;
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

  constructor(
    private route: ActivatedRoute,
    wahlservice: WahlSelectionService
  ) {
    this.wahl = wahlservice.wahlSubject.getValue() ? 19 : 20;
    wahlservice.is2017$.subscribe((selected2017: boolean) => {
      this.wahl = selected2017 ? 19 : 20;
      this.results = []
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
      });
    REST_GET(`20/wahlkreis/${this.nummer}/erststimmen`)
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
      this.results.length > 0;
  }

}
