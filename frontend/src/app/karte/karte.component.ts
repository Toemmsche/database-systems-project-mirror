import {Component, ElementRef, Input, OnInit, QueryList, ViewChildren} from '@angular/core';
import {Begrenzung} from 'src/model/Begrenzung';
import {REST_GET} from 'src/util/ApiService';
import {Wahlkreissieger} from "../../model/Wahlkreissieger";
import {Wahlkreisstimmen} from "../../model/Wahlkreisstimmen";
import {WahlSelectionService} from "../service/wahl-selection.service";

@Component({
  selector   : 'app-karte',
  templateUrl: './karte.component.html',
  styleUrls  : ['./karte.component.scss']
})
export class KarteComponent implements OnInit {
  bData !: Array<Begrenzung>

  @Input()
  wahl: number = 20;

  @ViewChildren('begrenzung')
  begrenzungElements!: QueryList<ElementRef<SVGPathElement>>;

  // DATA
  wksData !: Array<Wahlkreissieger>
  wkpData !: Array<Wahlkreisstimmen>

  siegerTyp: number = 1;
  partei: string = "Gewinner";
  parteien !: Array<string>;

  constructor(private readonly wahlSelectionservice: WahlSelectionService) {
  }

  ngOnInit(): void {
    this.populateBegrenzungen();
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
    this.wahlSelectionservice.wahlSubject.subscribe((selection: number) => {
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

  colorWahlkreis(nummer: number, color: string): void {
    this.begrenzungElements.find(x => x.nativeElement.id === `karte_${nummer}`)
        ?.nativeElement
        .setAttribute('style', `fill: #${color};`);
  }

  resetColors() {
    for (let wk_nummer = 1; wk_nummer <= 299; wk_nummer++) {
      this.colorWahlkreis(wk_nummer, 'FFFFFF');
    }
  }

  updateWahlkreisColorsSieger() {
    this.wksData.forEach(wks => {
      const color = this.siegerTyp === 1 ? wks.erststimme_sieger_farbe : wks.zweitstimme_sieger_farbe;
      this.colorWahlkreis(wks.wk_nummer, color);
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
      this.colorWahlkreis(wkp.wk_nummer, color);
    });
  }

  updateMap() {
    this.resetColors();
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
