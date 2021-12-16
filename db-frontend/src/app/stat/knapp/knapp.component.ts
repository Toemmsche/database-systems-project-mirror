import {Component, OnInit} from '@angular/core';
import {KnapperSiegOderNierderlage} from "../../../model/KnapperSiegOderNierderlage";
import {REST_GET} from "../../../util";

@Component({
  selector: 'app-knapp',
  templateUrl: './knapp.component.html',
  styleUrls: ['./knapp.component.scss']
})
export class KnappComponent implements OnInit {

  columnsToDisplay = [
    'sieger_partei',
    'verlierer_partei',
    'wahlkreis',
    'differenz_stimmen'
  ];
  knappData !: Array<KnapperSiegOderNierderlage>;

  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET('20/stat/knapp')
      .then(response => response.json())
      .then((data: Array<KnapperSiegOderNierderlage>) => {
        this.knappData = data.sort((a, b) => {
          return a.sieger_partei.localeCompare(b.sieger_partei);
        })
      })
  }

  knappLoaded(): boolean {
    return this.knappData != null && this.knappData.length > 0;
  }

}
