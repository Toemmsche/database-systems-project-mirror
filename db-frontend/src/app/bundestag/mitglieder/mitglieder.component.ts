import {Component, OnInit, ViewChild} from '@angular/core';
import {MDB} from "../../../model/MDB";
import {REST_GET} from "../../../util";
import {MatPaginator} from "@angular/material/paginator";
import {MatTableDataSource} from "@angular/material/table";
import {WahlSelectionService} from "../../service/wahl-selection.service";

@Component({
  selector: 'app-mitglieder',
  templateUrl: './mitglieder.component.html',
  styleUrls: ['./mitglieder.component.scss']
})
export class MitgliederComponent implements OnInit {


  wahl !: number;
  columnsToDisplay = ['vorname', 'nachname', 'partei', 'geburtsjahr', 'grund'];

  mdbData !: Array<MDB>;
  mdbDataSource !: MatTableDataSource<MDB>

  @ViewChild('mdbPaginator')
  mdbPaginator !: MatPaginator;

  constructor(
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.mdbData = [];
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    this.populate();
  }

  populate(): void {
    REST_GET(`${this.wahl}/mdb`)
      .then(response => response.json())
      .then((data: Array<MDB>) => {
        data = data.sort((a, b) => a.nachname.localeCompare(b.nachname));
        this.mdbDataSource = new MatTableDataSource(data); // TODO
        this.mdbDataSource.paginator = this.mdbPaginator;
        this.mdbData = data;
      });
  }

  mdbLoaded(): boolean {
    return this.mdbData != null && this.mdbData.length > 0;
  }
}
