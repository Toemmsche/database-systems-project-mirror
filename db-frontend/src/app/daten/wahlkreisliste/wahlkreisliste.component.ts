import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util";
import {WahlkreisKurz} from "../../../model/WahlkreisKurz";

@Component({
  selector: 'app-wahlkreisliste',
  templateUrl: './wahlkreisliste.component.html',
  styleUrls: ['./wahlkreisliste.component.scss']
})
export class WahlkreislisteComponent implements OnInit {

  wahl !: number;
  wahlkreise !: Array<WahlkreisKurz>;

  constructor(private readonly wahlservice: WahlSelectionService) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.wahlkreise = []
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    this.populate()
  }

  populate(): void {
    REST_GET(`${this.wahl}/wahlkreis`)
      .then(response => response.json())
      .then((data : Array<WahlkreisKurz>) => {
        this.wahlkreise = data;
      })
  }

  wahlkreiseLoaded() {
    return this.wahlkreise != null && this.wahlkreise.length > 0;
  }
}
