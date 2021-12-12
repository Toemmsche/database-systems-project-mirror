import {Component, OnInit} from '@angular/core';
import {Ueberhang} from "../../../model/Ueberhang";
import {REST_GET} from "../../../util";

@Component({
             selector   : 'app-ueberhang',
             templateUrl: './ueberhang.component.html',
             styleUrls  : ['./ueberhang.component.scss']
           })
export class UeberhangComponent implements OnInit {

  columnsToDisplay = ['bundesland', 'partei', 'ueberhang'];
  ueberhangData !: Array<Ueberhang>;

  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET('20/ueberhang')
      .then(response => response.json())
      .then((data: Array<Ueberhang>) => {
        this.ueberhangData = data
          .sort((a, b) => a.bundesland.localeCompare(b.bundesland))
          .filter(u => u.ueberhang > 0);
      })
  }

  ueberhangLoaded(): boolean {
    return this.ueberhangData != null && this.ueberhangData.length > 0;
  }

}
