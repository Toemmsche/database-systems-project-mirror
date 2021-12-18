import { Component, OnInit, ViewChild } from '@angular/core';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import { Wahlkreissieger } from "../../../model/Wahlkreissieger";
import { REST_GET } from "../../../util";
import { KarteComponent } from '../karte.component';

@Component({
  selector: 'app-wahlkreissieger',
  templateUrl: './wahlkreissieger.component.html',
  styleUrls: ['./wahlkreissieger.component.scss']
})
export class WahlkreissiegerComponent implements OnInit {

  columnsToDisplay = [
    'nummer',
    'name',
    'erststimme-sieger',
    'zweitstimme-sieger'
  ]
  wksData !: Array<Wahlkreissieger>

  @ViewChild('karteSieger')
  karteSieger!: KarteComponent;
  siegerTyp: number = 1;

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
        this.updateWahlkreisColors();
      })
  }

  wksLoaded(): boolean {
    return this.wksData != null && this.wksData.length > 0;
  }

  onReady(): void {
    this.populate();
  }

  updateWahlkreisColors() {
    this.wksData.forEach(wks => {
      const color = this.siegerTyp === 1 ? wks.erststimme_sieger_farbe : wks.zweitstimme_sieger_farbe;
      this.karteSieger.colorWahlkreis(wks.wk_nummer, color);
    });
  }

  onSiegerTypChange() {
    this.updateWahlkreisColors();
  }
}
