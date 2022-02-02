import {Component, Input, OnDestroy, OnInit, ViewChild} from '@angular/core';
import { Subscription } from 'rxjs';
import {Begrenzung} from 'src/model/Begrenzung';
import {REST_GET} from 'src/util/ApiService';
import {Wahlkreissieger} from "../../model/Wahlkreissieger";
import {Wahlkreisstimmen} from "../../model/Wahlkreisstimmen";
import {WahlSelectionService} from "../service/wahl-selection.service";
import { SvgKarteComponent } from './svg-karte/svg-karte.component';

@Component({
  selector   : 'app-karte',
  templateUrl: './karte.component.html',
  styleUrls  : ['./karte.component.scss']
})
export class KarteComponent implements OnInit, OnDestroy {
  bData !: Array<Begrenzung>

  @Input()
  wahl: number = 20;

  @ViewChild(SvgKarteComponent) karte !: SvgKarteComponent;

  // DATA
  wksData !: Array<Wahlkreissieger>
  wkpData !: Array<Wahlkreisstimmen>

  siegerTyp: number = 1;
  partei: string = "Gewinner";
  parteien !: Array<string>;
  wahlSubscription !: Subscription;

  constructor(private readonly wahlSelectionservice: WahlSelectionService) {
  }

  ngOnInit(): void {
    this.populateBegrenzungen();
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populateBegrenzungen(): void {
    REST_GET(`${this.wahl}/karte`)
      .then(response => response.json())
      .then((data: Array<Begrenzung>) => {
        this.bData = data;
        this.ready();
      })
  }

  ready(): void {
    this.populateDaten(this.wahlSelectionservice.wahlSubject.getValue());
    this.wahlSubscription = this.wahlSelectionservice.wahlSubject.subscribe((selection: number) => {
      this.populateDaten(selection);
    });
  }

  populateDaten(wahl: number): void {
    const nummer = this.wahlSelectionservice.getWahlNumber(wahl);
    REST_GET(`${nummer}/wahlkreissieger`)
      .then(response => response.json())
      .then((data: Array<Wahlkreissieger>) => {
        this.wksData = data.sort((a, b) => a.wk_nummer - b.wk_nummer);
        this.updateMap();
      });
    REST_GET(`${nummer}/wahlkreisergebnisse`)
      .then(response => response.json())
      .then((data: Array<Wahlkreisstimmen>) => {
        this.wkpData = data;
        this.parteien = [...new Set(this.wkpData.map(wk => wk.partei))].sort((a, b) => a.localeCompare(b));
        this.updateMap();
      });
  }

  wksLoaded(): boolean {
    return this.wksData != null && this.wksData.length > 0;
  }

  bDataLoaded() {
    return this.bData != null && this.bData.length > 0;
  }

  updateWahlkreisColorsSieger() {
    this.wksData.forEach(wks => {
      const color = this.siegerTyp === 1 ? wks.erststimme_sieger_farbe : wks.zweitstimme_sieger_farbe;
      this.karte.colorWahlkreis(wks.wk_nummer, color);
    });
  }

  updateWahlkreisColorsPartei() {
    const filteredData: Array<Wahlkreisstimmen> = this.wkpData.filter(wkp => wkp.partei ===
      this.partei &&
      wkp.stimmentyp ===
      this.siegerTyp);
    const maxRelative: number = filteredData.reduce((prev, wkp) => Math.max(prev, wkp.rel_stimmen), 0);
    filteredData.forEach(wkp => {
      const alpha = Math.round(wkp.rel_stimmen * 255 / maxRelative);
      const color = wkp.partei_farbe + (alpha < 16 ? '0' : '') + alpha.toString(16);
      this.karte.colorWahlkreis(wkp.wk_nummer, color);
    });
  }

  updateMap() {
    this.karte.resetColors();
    if (this.partei === 'Gewinner') {
      this.updateWahlkreisColorsSieger();
    } else {
      this.updateWahlkreisColorsPartei();
    }
  }

  onSiegerTypChange() {
    this.updateMap();
  }

  onParteiChange() {
    this.updateMap();
  }
}
