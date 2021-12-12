import {Component, OnInit} from '@angular/core';
import {Knapp} from "../../../model/Knapp";
import {REST_GET} from "../../../util";

@Component({
             selector   : 'app-knapp',
             templateUrl: './knapp.component.html',
             styleUrls  : ['./knapp.component.scss']
           })
export class KnappComponent implements OnInit {

  columnsToDisplay = ['partei', 'wahlkreis', 'vorsprung_prozent'];
  knappData !: Array<Knapp>;

  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET('20/stat/knapp')
      .then(response => response.json())
      .then((data: Array<Knapp>) => {
        this.knappData = data.sort((a, b) => {
          return a.partei.localeCompare(b.partei);
        })
      })
  }

  knappLoaded(): boolean {
    return this.knappData != null && this.knappData.length > 0;
  }

}
