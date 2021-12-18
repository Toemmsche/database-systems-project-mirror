import {Component, OnInit} from '@angular/core';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import {KnapperSiegOderNierderlage} from "../../../model/KnapperSiegOderNierderlage";
import {REST_GET} from "../../../util";

@Component({
  selector: 'app-knapp',
  templateUrl: './knapp.component.html',
  styleUrls: ['./knapp.component.scss']
})
export class KnappComponent implements OnInit {

  columnsToDisplay = [
    'sieger_partei',
    'verlierer_partei',
    'wahlkreis',
    'differenz_stimmen'
  ];
  knappData !: Array<KnapperSiegOderNierderlage>;

  constructor(private readonly wahlSelectionService: WahlSelectionService) {
  }

  ngOnInit(): void {
    this.populate(this.wahlSelectionService.wahlSubject.getValue());
    this.wahlSelectionService.wahlSubject.subscribe((selection: number) => {
      this.populate(selection);
    });
  }

  populate(wahl: number): void {
    const nummer = this.wahlSelectionService.getWahlNumber(wahl);
    REST_GET(`${nummer}/stat/knapp`)
      .then(response => response.json())
      .then((data: Array<KnapperSiegOderNierderlage>) => {
        this.knappData = data.sort((a, b) => {
          return a.differenz_stimmen - b.differenz_stimmen;
        })
      })
  }

  knappLoaded(): boolean {
    return this.knappData != null && this.knappData.length > 0;
  }

}
