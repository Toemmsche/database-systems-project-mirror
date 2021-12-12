import {Component, OnInit} from '@angular/core';
import {Wahlkreis} from "../../../model/Walhkreis";
import {Wahlkreissieger} from "../../../model/Wahlkreissieger";
import {REST_GET} from "../../../util";

@Component({
             selector   : 'app-wahlkreissieger',
             templateUrl: './wahlkreissieger.component.html',
             styleUrls  : ['./wahlkreissieger.component.scss']
           })
export class WahlkreissiegerComponent implements OnInit {

  columnsToDisplay = [
    'nummer',
    'name',
    'erststimme-sieger',
    'zweitstimme-sieger'
  ]
  wksData !: Array<Wahlkreissieger>

  constructor() {
  }

  ngOnInit(): void {
    this.populate()
  }

  populate(): void {
    REST_GET('20/wahlkreissieger')
      .then(response => response.json())
      .then((data: Array<Wahlkreissieger>) => {
        this.wksData = data.sort((a, b) => a.nummer - b.nummer);
      })
  }

  wksLoaded(): boolean {
    return this.wksData != null && this.wksData.length > 0;
  }
}
