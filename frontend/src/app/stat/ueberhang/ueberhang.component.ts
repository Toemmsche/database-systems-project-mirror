import {Component, OnDestroy, OnInit} from '@angular/core';
import { Subscription } from 'rxjs';
import {WahlSelectionService} from 'src/app/service/wahl-selection.service';
import {Ueberhang} from "../../../model/Ueberhang";
import {REST_GET} from "../../../util/ApiService";

@Component({
  selector   : 'app-ueberhang',
  templateUrl: './ueberhang.component.html',
  styleUrls  : ['./ueberhang.component.scss']
})
export class UeberhangComponent implements OnInit, OnDestroy {

  columnsToDisplay = ['bundesland', 'partei', 'ueberhang'];
  wahl !: number;
  ueberhangData !: Array<Ueberhang>;
  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {}

  ngOnInit(): void {
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.ueberhangData = [];
      this.populate();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
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
