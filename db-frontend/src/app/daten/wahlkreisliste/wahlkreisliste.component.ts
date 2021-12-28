import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util";
import {Wahlkreis} from "../../../model/Walhkreis";
import {MatSelectChange} from "@angular/material/select";

@Component({
  selector: 'app-wahlkreisliste',
  templateUrl: './wahlkreisliste.component.html',
  styleUrls: ['./wahlkreisliste.component.scss']
})
export class WahlkreislisteComponent implements OnInit {

  wahl !: number;
  wahlkreise !: Array<Wahlkreis>;
  wahlkreise_filtered !: Array<Wahlkreis>;
  laender !: Set<String>;

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
      .then((data: Array<Wahlkreis>) => {
        this.wahlkreise = data.sort((a, b) => a.wk_nummer - b.wk_nummer);
        this.laender = new Set(this.wahlkreise.map(wk => wk.land));
        this.laender.add("Alle");

        this.wahlkreise_filtered = this.wahlkreise.slice()
      })
  }

  onFilterChange(event: MatSelectChange): void {
    this.wahlkreise_filtered = this.wahlkreise.filter(wk =>  event.value == "Alle" || wk.land == event.value );
  }

  wahlkreiseLoaded() {
    return this.wahlkreise != null && this.wahlkreise.length > 0;
  }
}
