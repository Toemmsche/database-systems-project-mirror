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

  sitzverteilung: Array<Sitzverteilung> = [];
  columnsToDisplay = ['partei', 'sitze'];
  sitzVerteilungConfig = {
    type: 'doughnut',
    data: {
      labels: [] as Array<string>,
      datasets: [
        {
          label: "Sitzverteilung im Deutschen Bundestag",
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
    },
    loaded: false
  }


  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate() {
    REST_GET('20/sitzverteilung').then((data: Array<Sitzverteilung>) => {
      // Save for later
      this.sitzverteilung = data;

      // Populate half-pie chart
      const sData = this.sitzVerteilungConfig.data;
      sData.labels = this.sitzverteilung.map((row) => row.kuerzel);
      sData.datasets[0].data = this.sitzverteilung.map((row) => row.sitze);
      sData.datasets[0].backgroundColor = this.sitzverteilung.map((row) => '#' + row.farbe);
      this.sitzVerteilungConfig.loaded = true;
    });
  }

  sitzVerteilungLoaded() {
    return this.sitzVerteilungConfig.loaded;
  }
}
