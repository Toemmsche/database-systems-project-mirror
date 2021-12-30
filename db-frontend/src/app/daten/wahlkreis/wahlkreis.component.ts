import {Component, Input, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util";
import {Wahlkreis} from "../../../model/Walhkreis";
import {ParteiErgebnis} from "../../../model/ParteiErgebnis";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {MatSlideToggleChange} from "@angular/material/slide-toggle";

@Component({
  selector   : 'app-wahlkreis',
  templateUrl: './wahlkreis.component.html',
  styleUrls  : ['./wahlkreis.component.scss']
})
export class WahlkreisComponent implements OnInit {

  @Input()
  nummer !: number;
  wahl !: number;
  useEinzelstimmen: boolean = false;

  wahlkreis !: Wahlkreis;
  erststimmenergebnisse !: Array<ParteiErgebnis>;
  erststimmenConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Erststimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
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

  zweitstimmenergebnisse !: Array<ParteiErgebnis>;
  zweitstimmenConfig = {
    type   : 'bar',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Zweitstimmen",
          borderWidth    : 1,
          data           : [] as Array<number>,
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
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.erststimmenergebnisse = [];
      this.zweitstimmenergebnisse = [];
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
      });
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}/erststimmen${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
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
        const chartData = this.erststimmenConfig.data;
        chartData.labels = data.map((result) => result.partei);
        chartData.datasets[0].data = data.map((result) => result.abs_stimmen);
        chartData.datasets[0].backgroundColor = data.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.erststimmenergebnisse = data;
      });
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}/zweitstimmen${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
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
        const chartData = this.zweitstimmenConfig.data;
        chartData.labels = data.map((result) => result.partei);
        chartData.datasets[0].data = data.map((result) => result.abs_stimmen);
        chartData.datasets[0].backgroundColor = data.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.zweitstimmenergebnisse = data;
      });
  }

  wahlkreisLoaded(): boolean {
    return this.wahlkreis != null &&
      this.erststimmenergebnisse != null &&
      this.erststimmenergebnisse.length > 0 &&
      this.zweitstimmenergebnisse != null &&
      this.zweitstimmenergebnisse.length > 0;
  }

  onEinzelstimmenToggleChanged(event: MatSlideToggleChange) {
    if (this.nummer != 222 || this.wahl != 20) {
      window.alert("Einzelstimmen liegen nicht vor")
      return;
    }
    this.useEinzelstimmen = event.checked;
    this.erststimmenergebnisse = [];
    this.zweitstimmenergebnisse = [];
    this.ngOnInit();
  }
}
