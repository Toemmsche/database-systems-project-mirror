import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util/ApiService";
import {Wahlkreis} from "../../../model/Walhkreis";
import {ParteiErgebnis} from "../../../model/ParteiErgebnis";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {MatSlideToggleChange} from "@angular/material/slide-toggle";
import { Subscription } from 'rxjs';

@Component({
  selector   : 'app-wahlkreis',
  templateUrl: './wahlkreis.component.html',
  styleUrls  : ['./wahlkreis.component.scss']
})
export class WahlkreisComponent implements OnInit, OnDestroy {

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
  wahlSubscription !: Subscription;

  constructor(
    private route: ActivatedRoute,
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    this.wahlSubscription = wahlservice.wahlSubject.subscribe((selection: number) => {
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

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
      });
    REST_GET(`${this.wahl}/wahlkreis/${this.nummer}/stimmen${this.useEinzelstimmen ? "?einzelstimmen=true" : ""}`)
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
        const esData = data.filter(pe => pe.stimmentyp == 1);
        const esChartData = this.erststimmenConfig.data;
        esChartData.labels = esData.map((result) => result.partei);
        esChartData.datasets[0].data = esData.map((result) => result.abs_stimmen);
        esChartData.datasets[0].backgroundColor = esData.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.erststimmenergebnisse = esData;

        // Populate bar chart
        const zsData = data.filter(pe => pe.stimmentyp == 2);
        const zsChartData = this.zweitstimmenConfig.data;
        zsChartData.labels = zsData.map((result) => result.partei);
        zsChartData.datasets[0].data = zsData.map((result) => result.abs_stimmen);
        zsChartData.datasets[0].backgroundColor = zsData.map((result) => '#' +
          result.partei_farbe);

        // Save for later
        this.zweitstimmenergebnisse = zsData;
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
