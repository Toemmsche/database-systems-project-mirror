import {Component, OnInit} from '@angular/core';
import {REST_GET} from "../../../util";
import {Sitzverteilung} from "../../../model/Sitzverteilung";

@Component({
  selector: 'app-sitzverteilung',
  templateUrl: './sitzverteilung.component.html',
  styleUrls: ['./sitzverteilung.component.scss']
})
export class SitzverteilungComponent implements OnInit {

  //TODO support for 2017

  sitzverteilung !: Array<Sitzverteilung>;
  columnsToDisplay = ['partei', 'sitze'];
  sitzVerteilungConfig = {
    type: 'doughnut',
    data: {
      labels: [] as Array<string>,
      datasets: [
        {
          label: "Sitze",
          hoverOffset: 4,
          data: [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }
      ]
    },
    options: {
      rotation: Math.PI,
      circumference: Math.PI,
      responsive: true,
      maintainAspectRatio: true
    }
  }


  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate() {
    REST_GET('20/sitzverteilung')
      .then(response => response.json())
      .then((data: Array<Sitzverteilung>) => {
        // Populate half-pie chart
        const chartData = this.sitzVerteilungConfig.data;
        chartData.labels = data.map((row) => row.partei);
        chartData.datasets[0].data = data.map((row) => row.sitze);
        chartData.datasets[0].backgroundColor = data.map((row) => '#' +
          row.partei_farbe);

        // Save for later
        this.sitzverteilung = data;
      });
  }

  sitzVerteilungLoaded() {
    return this.sitzverteilung != null && this.sitzverteilung.length > 0;
  }
}