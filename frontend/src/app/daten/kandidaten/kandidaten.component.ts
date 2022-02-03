import { AfterViewInit, Component, Input, OnInit, ViewChild } from '@angular/core';
import { Subscription } from "rxjs";
import { WahlSelectionService } from "../../service/wahl-selection.service";
import Kandidat from "../../../model/Kandidat";
import { REST_GET } from "../../../util/ApiService";
import { MatTableDataSource } from "@angular/material/table";
import { MatPaginator } from "@angular/material/paginator";
import { FormControl } from "@angular/forms";

@Component({
  selector: 'app-kandidaten',
  templateUrl: './kandidaten.component.html',
  styleUrls: ['./kandidaten.component.scss']
})
export class KandidatenComponent implements OnInit, AfterViewInit {
  wahl !: number;

  @Input("hidefilter")
  hideFilter !: boolean;

  columnsToDisplay = [
    'titel',
    'nachname',
    'vorname',
    'partei',
    'geburtsjahr',
    'geschlecht',
    'beruf',
    'partei',
    'bundesland',
    'listenplatz',
    'wahlkreis',
    'erststimmenanteil'
  ];

  kandidatenDataSource: MatTableDataSource<Kandidat> = new MatTableDataSource();

  @ViewChild('paginator')
  kandidatenTablePaginator !: MatPaginator


  parteien !: Set<string>;
  parteiFilter = new FormControl("")
  geschlechter !: Set<string>
  geschlechtFilter = new FormControl("");
  mandatFilter = new FormControl("")
  bundeslaender !: Set<string>
  bundeslandFilter = new FormControl("");
  wahlkreise !: Set<string>
  wahlkreisFilter = new FormControl("");
  titel !: Set<string>
  titelFilter = new FormControl("");

  filter = {
    partei: "Alle",
    mandat: "Alle",
    bundesland: "Alle",
    geschlecht: "Alle",
    titel: "Alle",
    wahlkreis: "Alle"
  }

  filterPredicate = (k: Kandidat, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.partei === all || (k.partei === filter.partei)) &&
           (filter.mandat === all ||
            (filter.mandat === "MDB" && k.ist_einzug) ||
            (filter.mandat === "Direktmandat" && k.ist_direktmandat) ||
            (filter.mandat === "Listenmandat" && !k.ist_direktmandat)) &&
           (filter.bundesland === all || k.bundesland === filter.bundesland) &&
           (filter.geschlecht === all || k.geschlecht === filter.geschlecht) &&
           (filter.titel === all || k.titel === filter.titel) &&
           (filter.wahlkreis === all || k.wk_nummer + "-" + k.wk_name === filter.wahlkreis);
  }

  wahlSubscription !: Subscription;

  constructor(
    private readonly wahlservice: WahlSelectionService
  ) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    this.wahlSubscription = wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.kandidatenDataSource.data = [];
      this.ngAfterViewInit();
    });
  }

  ngOnInit(): void {
    this.initFilterListeners();
  }

  ngAfterViewInit() {
    // Paginator
    this.kandidatenDataSource.paginator = this.kandidatenTablePaginator
    this.populate();
  }

  updateFilter(): void {
    this.kandidatenDataSource.filter = JSON.stringify(this.filter);
  }

  initFilterListeners(): void {
    this.mandatFilter.valueChanges.subscribe(value => {
      this.filter.mandat = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.geschlechtFilter.valueChanges.subscribe(value => {
      this.filter.geschlecht = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.titelFilter.valueChanges.subscribe(value => {
      this.filter.titel = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.parteiFilter.valueChanges.subscribe(value => {
      this.filter.partei = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.bundeslandFilter.valueChanges.subscribe(value => {
      this.filter.bundesland = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.wahlkreisFilter.valueChanges.subscribe(value => {
      this.filter.wahlkreis = value;
      // emulate user filter input
      this.updateFilter();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/kandidaten`)
      .then(response => response.json())
      .then((data: Array<Kandidat>) => {
        data = data.sort((a, b) => a.nachname.localeCompare(b.nachname));
        this.parteien = new Set(data.map(kandidat => kandidat.partei));
        this.geschlechter = new Set(data.map(kandidat => kandidat.geschlecht));
        this.titel = new Set(data.filter(kandidat => kandidat.titel != "").map(kandidat => kandidat.titel));
        this.bundeslaender = new Set(data.filter(kandidat => kandidat.bundesland != null)
                                         .map(kandidat => kandidat.bundesland ?? ""));
        this.wahlkreise = new Set(data.filter(kandidat => kandidat.wk_nummer != null)
                                      .sort((a, b) => (a.wk_nummer ?? 0) - (b.wk_nummer ?? 0)) // for TS
                                      .map(kandidat => kandidat.wk_nummer + "-" + kandidat.wk_name));
        // Filter
        this.kandidatenDataSource.filterPredicate = this.filterPredicate;
        this.kandidatenDataSource.data = data;
      });
  }

  kandidatenLoaded(): boolean {
    return this.kandidatenDataSource.data != null && this.kandidatenDataSource.data.length > 0;
  }
}
