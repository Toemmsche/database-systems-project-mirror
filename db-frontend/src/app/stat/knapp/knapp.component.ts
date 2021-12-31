import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {KnapperSiegOderNierderlage} from "../../../model/KnapperSiegOderNierderlage";
import {REST_GET} from "../../../util";

@Component({
  selector   : 'app-knapp',
  templateUrl: './knapp.component.html',
  styleUrls  : ['./knapp.component.scss']
})
export class KnappComponent implements OnInit {

  wahl !: number;
  columnsToDisplay = [
    'sieger-partei',
    'verlierer-partei',
    'wahlkreis',
    'differenz-stimmen'
  ];
  siegerParteien !: Set<string>;
  siegerParteiFilter: string = "Alle";
  verliererParteien !: Set<string>;
  verliererParteiFilter: string = "Alle";
  istSiegFilter : string = "Beide";
  knappData !: Array<KnapperSiegOderNierderlage>;
  filteredKnappData !: Array<KnapperSiegOderNierderlage>;

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.knappData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/stat/knapp`)
      .then(response => response.json())
      .then((data: Array<KnapperSiegOderNierderlage>) => {
        this.knappData = data.sort((a, b) => {
          return a.differenz_stimmen - b.differenz_stimmen;
        })
        this.siegerParteien = new Set(this.knappData.map(k => k.sieger_partei));
        this.siegerParteien.add("Alle");
        this.verliererParteien = new Set(this.knappData.map(k => k.verlierer_partei));
        this.verliererParteien.add("Alle");
        this.filteredKnappData = this.knappData.slice();
      })
  }

  knappLoaded(): boolean {
    return this.knappData != null && this.knappData.length > 0;
  }

  updateFiltered(): void {
    this.filteredKnappData = this.knappData.filter(k =>
      (this.siegerParteiFilter == "Alle" || k.sieger_partei == this.siegerParteiFilter) &&
      (this.verliererParteiFilter == "Alle" || k.verlierer_partei == this.verliererParteiFilter) &&
      (this.istSiegFilter == "Beide" || k.is_sieg && this.istSiegFilter == "Sieg" || !k.is_sieg && this.istSiegFilter == "Niederlage"));
  }

}
