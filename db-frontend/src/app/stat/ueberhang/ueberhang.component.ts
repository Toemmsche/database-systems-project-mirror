import { Component, OnInit } from '@angular/core';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import { Ueberhang } from "../../../model/Ueberhang";
import { REST_GET } from "../../../util";

@Component({
  selector: 'app-ueberhang',
  templateUrl: './ueberhang.component.html',
  styleUrls: ['./ueberhang.component.scss']
})
export class UeberhangComponent implements OnInit {

  columnsToDisplay = ['bundesland', 'partei', 'ueberhang'];
  ueberhangData !: Array<Ueberhang>;

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
    REST_GET(`${nummer}/ueberhang`)
      .then(response => response.json())
      .then((data: Array<Ueberhang>) => {
        this.ueberhangData = data.sort((a, b) => b.ueberhang - a.ueberhang);
      });
  }

  ueberhangLoaded(): boolean {
    return this.ueberhangData != null && this.ueberhangData.length > 0;
  }

}
