import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util";
import {ParteiErgebnisVergleich} from "../../../model/ParteiErgebnisVergleich";

@Component({
  selector   : 'app-aqvergleich',
  templateUrl: './aqvergleich.component.html',
  styleUrls  : ['./aqvergleich.component.scss']
})
export class AQVergleichComponent implements OnInit {

  wahl !: number;
  aqData !: Array<ParteiErgebnisVergleich>
  aqNiedrigConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        },
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
  aqHochConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        },
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
      this.aqData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  populate() {
    REST_GET(`${this.wahl}/stat/aqvergleich`)
      .then(response => response.json())
      .then((data: Array<ParteiErgebnisVergleich>) => {
        data = data.sort((a, b) => {
          if (a.partei == 'Sonstige') {
            return 1;
          } else if (b.partei == 'Sonstige') {
            return -1;
          }
          return b.abs_stimmen - a.abs_stimmen;
        });



        // Populate bar chart
        const niedrigData = data.filter(aq => aq.typ == 'niedrig')
        const niedrigChartData = this.aqNiedrigConfig.data;
        niedrigChartData.labels = niedrigData.map((result) => result.partei);
        niedrigChartData.datasets[0].data = niedrigData.map((result) => result.abs_stimmen);
        niedrigChartData.datasets[0].backgroundColor = niedrigData.map((result) => '#' +
          result.partei_farbe);

        // Make sure chart is refreshed when new data is available
        this.aqNiedrigConfig.data = Object.assign({}, niedrigChartData);

        const hochData = data.filter(aq => aq.typ == 'hoch')
        const hochChartData = this.aqHochConfig.data;
        hochChartData.labels = hochData.map((result) => result.partei);
        hochChartData.datasets[0].data = hochData.map((result) => result.abs_stimmen);
        hochChartData.datasets[0].backgroundColor = hochData.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.aqData = data;
      });
  }

  aqLoaded() {
    return this.aqData != null && this.aqData.length > 0;
  }
}
