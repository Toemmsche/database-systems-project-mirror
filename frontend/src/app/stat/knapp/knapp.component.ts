import {Component, OnDestroy, OnInit} from '@angular/core';
import { Subscription } from 'rxjs';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {KnapperSiegOderNierderlage} from "../../../model/KnapperSiegOderNierderlage";
import {REST_GET} from "../../../util/ApiService";

@Component({
  selector   : 'app-knapp',
  templateUrl: './knapp.component.html',
  styleUrls  : ['./knapp.component.scss']
})
export class KnappComponent implements OnInit, OnDestroy {

  wahl !: number;
  columnsToDisplay = [
    'sieger-partei',
    'verlierer-partei',
    'wahlkreis',
    'stimmen-sieger-partei',
    'stimmen-verlierer-partei',
    'differenz-stimmen',
    'differenz-relativ'
  ];
  siegerParteien !: Set<string>;
  siegerParteiFilter: string = "Alle";
  verliererParteien !: Set<string>;
  verliererParteiFilter: string = "Alle";
  istSiegFilter : string = "Beide";
  knappData !: Array<KnapperSiegOderNierderlage>;
  filteredKnappData !: Array<KnapperSiegOderNierderlage>;

  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.knappData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/stat/knapp`)
      .then(response => response.json())
      .then((data: Array<KnapperSiegOderNierderlage>) => {
        this.knappData = data.sort((a, b) => {
          return a.differenz_stimmen - b.differenz_stimmen;
        })
        this.siegerParteien = new Set(this.knappData.map(k => k.sieger_partei));
        this.verliererParteien = new Set(this.knappData.map(k => k.verlierer_partei));
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
