import { AfterViewInit, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { MDB } from "../../../model/MDB";
import { REST_GET } from "../../../util/ApiService";
import { WahlSelectionService } from "../../service/wahl-selection.service";
import { MatTableDataSource } from "@angular/material/table";
import { MatPaginator } from "@angular/material/paginator";
import { FormControl } from "@angular/forms";

@Component({
  selector: 'app-mitglieder',
  templateUrl: './mitglieder.component.html',
  styleUrls: ['./mitglieder.component.scss']
})
export class MitgliederComponent implements OnInit, OnDestroy, AfterViewInit {

  wahl !: number;
  columnsToDisplay = ['nachname', 'vorname', 'partei', 'geburtsjahr', 'geschlecht', 'grund'];
  mdbDataSource: MatTableDataSource<MDB> = new MatTableDataSource();

  @ViewChild('paginator')
  mdbTablePaginator !: MatPaginator


  parteien !: Set<string>;
  parteiFilter = new FormControl("")
  geschlechter !: Set<string>
  geschlechtFilter = new FormControl("");

  filter = {
    partei: "Alle",
    geschlecht: "Alle",
  }

  filterPredicate = (mdb: MDB, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.partei === all || (mdb.partei === filter.partei)) &&
           (filter.geschlecht === all || mdb.geschlecht === filter.geschlecht);
  }

  wahlSubscription !: Subscription;

  constructor(
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    this.wahlSubscription = wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.mdbDataSource = new MatTableDataSource<MDB>();
      this.ngAfterViewInit();
    });
  }

  ngOnInit(): void {
    this.initFilterListeners();
  }

  ngAfterViewInit() {
    // Paginator
    this.mdbDataSource.paginator = this.mdbTablePaginator
    this.populate();
  }

  updateFilter(): void {
    this.mdbDataSource.filter = JSON.stringify(this.filter);
  }

  initFilterListeners(): void {
    this.geschlechtFilter.valueChanges.subscribe(value => {
      this.filter.geschlecht = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.parteiFilter.valueChanges.subscribe(value => {
      this.filter.partei = value;
      // emulate user filter input
      this.updateFilter();
    });
  }


  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/mdb`)
      .then(response => response.json())
      .then((data: Array<MDB>) => {
        data = data.sort((a, b) => a.nachname.localeCompare(b.nachname));
        this.parteien = new Set(data.map(mdb => mdb.partei));
        this.geschlechter = new Set(data.map(mdb => mdb.geschlecht));

        // Filter
        this.mdbDataSource.filterPredicate = this.filterPredicate;
        this.mdbDataSource.data = data;
      });
  }

  mdbLoaded(): boolean {
    return this.mdbDataSource.data != null && this.mdbDataSource.data.length > 0;
  }
}
