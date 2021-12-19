import { Component, OnInit, ViewChild } from '@angular/core';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import { Wahlkreisstimmen } from 'src/model/Wahlkreisstimmen';
import { Wahlkreissieger } from "../../../model/Wahlkreissieger";
import { REST_GET } from "../../../util";
import { KarteComponent } from '../karte.component';

@Component({
  selector: 'app-wahlkreissieger',
  templateUrl: './wahlkreissieger.component.html',
  styleUrls: ['./wahlkreissieger.component.scss']
})
export class WahlkreissiegerComponent implements OnInit {

  wksData !: Array<Wahlkreissieger>
  wkpData !: Array<Wahlkreisstimmen>

  @ViewChild('karteSieger')
  karteSieger !: KarteComponent;
  siegerTyp: number = 1;
  partei: string = "Gewinner";
  parteien !: Array<string>;

  constructor(private readonly wahlSelectionservice: WahlSelectionService) {
  }

  ngOnInit(): void {
  }

  populate(wahl: number): void {
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

  onReady(): void {
    this.populate(this.wahlSelectionservice.wahlSubject.getValue());
    this.wahlSelectionservice.wahlSubject.subscribe((selection: number) => {
      this.populate(selection);
    });
  }

  resetColors() {
    for (let wk_nummer = 1; wk_nummer <= 299; wk_nummer++) {
      this.karteSieger.colorWahlkreis(wk_nummer, 'FFFFFF');
    }
  }

  updateWahlkreisColorsSieger() {
    this.wksData.forEach(wks => {
      const color = this.siegerTyp === 1 ? wks.erststimme_sieger_farbe : wks.zweitstimme_sieger_farbe;
      this.karteSieger.colorWahlkreis(wks.wk_nummer, color);
    });
  }

  updateWahlkreisColorsPartei() {
    const filteredData: Array<Wahlkreisstimmen> = this.wkpData.filter(wkp => wkp.partei === this.partei && wkp.stimmentyp === this.siegerTyp);
    const maxRelative: number = filteredData.reduce((prev, wkp) => Math.max(prev, wkp.rel_stimmen), 0);
    filteredData.forEach(wkp => {
      const alpha = Math.round(wkp.rel_stimmen * 255 / maxRelative);
      const color = wkp.partei_farbe + (alpha < 16 ? '0' : '') + alpha.toString(16);
      this.karteSieger.colorWahlkreis(wkp.wk_nummer, color);
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
