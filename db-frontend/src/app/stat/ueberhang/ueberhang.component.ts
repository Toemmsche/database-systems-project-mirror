import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {Ueberhang} from "../../../model/Ueberhang";
import {REST_GET} from "../../../util";

@Component({
  selector   : 'app-ueberhang',
  templateUrl: './ueberhang.component.html',
  styleUrls  : ['./ueberhang.component.scss']
})
export class UeberhangComponent implements OnInit {

  columnsToDisplay = ['bundesland', 'partei', 'ueberhang'];
  wahl !: number;
  ueberhangData !: Array<Ueberhang>;

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.ueberhangData = [];
      this.ngOnInit();
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/stat/ueberhang`)
      .then(response => response.json())
      .then((data: Array<Ueberhang>) => {
        this.ueberhangData = data.sort((a, b) => b.ueberhang - a.ueberhang);
      });
  }

  ueberhangLoaded(): boolean {
    return this.ueberhangData != null && this.ueberhangData.length > 0;
  }

}
