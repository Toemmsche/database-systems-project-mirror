import {Component, OnInit} from '@angular/core';
import {MDB} from "../../../model/MDB";
import {REST_GET} from "../../../util";
import {Sitzverteilung} from "../../../model/Sitzverteilung";

@Component({
  selector: 'app-mitglieder',
  templateUrl: './mitglieder.component.html',
  styleUrls: ['./mitglieder.component.scss']
})
export class MitgliederComponent implements OnInit {


  columnsToDisplay = ['vorname', 'nachname', 'partei', 'geburtsjahr', 'grund'];

  mdbData !: Array<MDB>;

  constructor() {
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET('20/mdb')
      .then(response => response.json())
      .then((data: Array<MDB>) => {
      this.mdbData = data.sort((a, b) => a.nachname.localeCompare(b.nachname));
    });
  }

  mdbLoaded(): boolean {
    return this.mdbData != null && this.mdbData.length > 0;
  }
}
