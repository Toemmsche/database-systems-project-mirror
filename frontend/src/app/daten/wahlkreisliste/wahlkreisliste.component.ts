import {Component, Input, OnInit} from '@angular/core';
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util/ApiService";
import {Wahlkreis} from "../../../model/Walhkreis";

@Component({
  selector   : 'app-wahlkreisliste',
  templateUrl: './wahlkreisliste.component.html',
  styleUrls  : ['./wahlkreisliste.component.scss']
})
export class WahlkreislisteComponent implements OnInit {

  @Input()
  routePrefix !: string;

  wahl !: number;
  wahlkreise !: Array<Wahlkreis>;
  filteredWahlkreise !: Array<Wahlkreis>;

  laender !: Set<String>;
  landFilter !: string;

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
        this.filteredWahlkreise = this.wahlkreise.slice()
      })
  }

  updateFiltered() {
    this.filteredWahlkreise = this.wahlkreise.filter(wk => this.landFilter == "Alle" || wk.land == this.landFilter);
  }

  wahlkreiseLoaded() {
    return this.wahlkreise != null && this.wahlkreise.length > 0;
  }
}
