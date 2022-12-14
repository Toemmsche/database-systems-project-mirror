import {AfterViewInit, Component, Input, OnInit, ViewChild} from "@angular/core";
import {Subscription} from "rxjs";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import Kandidat from "../../../model/Kandidat";
import {REST_GET} from "../../../util/ApiService";
import {MatTableDataSource} from "@angular/material/table";
import {MatPaginator} from "@angular/material/paginator";
import {FormControl, FormGroup} from "@angular/forms";
import {MatSort} from "@angular/material/sort";
import {containsLowerCase} from "../../../util/ArrayHelper";

@Component({
  selector   : "app-kandidaten",
  templateUrl: "./kandidaten.component.html",
  styleUrls  : ["./kandidaten.component.scss"]
})
export class KandidatenComponent implements OnInit, AfterViewInit {
  wahl !: number;

  @Input("hidefilter")
  hideFilter !: boolean;

  @Input("mdbOnly")
  mdbOnly !: boolean

  columnsToDisplay = [
    "titel",
    "nachname",
    "vorname",
    "geburtsjahr",
    "geschlecht",
    "beruf",
    "partei",
    "bundesland",
    "listenplatz",
    "wk_nummer",
    "rel_stimmen"
  ];

  kandidatenDataSource: MatTableDataSource<Kandidat> = new MatTableDataSource();

  @ViewChild("paginator")
  kandidatenTablePaginator !: MatPaginator

  @ViewChild(MatSort)
  kandidatenTableSort !: MatSort;

  @ViewChild("ngForm")
  filterFormGroup !: FormGroup

  titelFilter = new FormControl("");

  vornameFilter = new FormControl("");

  nachnameFilter = new FormControl("");

  geburtsjahrFilter = new FormControl("");

  geschlechter !: Set<string>
  geschlechtFilter = new FormControl("Alle");

  berufFilter = new FormControl("");

  parteiFilter = new FormControl("");

  mandatFilter = new FormControl("Alle")

  bundeslaender !: Set<string>
  bundeslandFilter = new FormControl("Alle");

  wahlkreisFilter = new FormControl("");

  relStimmenVonFilter = new FormControl("");
  relStimmenBisFilter = new FormControl("");

  filter = {
    titel        : "",
    vorname      : "",
    nachname     : "",
    geburtsjahr  : "",
    geschlecht   : "Alle",
    beruf        : "",
    partei       : "",
    mandat       : "Alle",
    bundesland   : "Alle",
    wahlkreis    : "",
    relStimmenVon: "",
    relStimmenBis: "",
  }

  filterPredicate = (k: Kandidat, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.titel === "" || containsLowerCase(k.titel, filter.titel)) &&
      (filter.vorname === "" || containsLowerCase(k.vorname, filter.vorname)) &&
      (filter.nachname === "" || containsLowerCase(k.nachname, filter.nachname)) &&
      (filter.geburtsjahr ===
        "" ||
        k.geburtsjahr !=
        null &&
        k.geburtsjahr.toString().indexOf(filter.geburtsjahr.toString()) !==
        -1) &&
      (filter.geschlecht === all || k.geschlecht === filter.geschlecht) &&
      (filter.beruf === "" || containsLowerCase(k.beruf, filter.beruf)) &&
      (filter.partei === "" || containsLowerCase(k.partei, filter.partei)) &&
      (filter.mandat === all || (filter.mandat === "MDB" && k.ist_einzug) ||
        (filter.mandat === "Direktmandat" && k.ist_einzug && k.ist_direktmandat) ||
        (filter.mandat === "Listenmandat" && k.ist_einzug && !k.ist_direktmandat)) &&
      (filter.bundesland === all || k.bundesland === filter.bundesland) &&
      (filter.wahlkreis === "" || containsLowerCase(k.wk_nummer + "-" + k.wk_name, filter.wahlkreis)) &&
      (filter.relStimmenVon ===
        "" ||
        (k.rel_stimmen != null && filter.relStimmenVon <= k.rel_stimmen * 100)) &&
      (filter.relStimmenBis ===
        "" ||
        (k.rel_stimmen != null && filter.relStimmenBis >= k.rel_stimmen * 100))
      ;
  }

  wahlSubscription !: Subscription;

  constructor(
    private readonly wahlservice: WahlSelectionService
  ) {
  }

  ngOnInit(): void {
    this.initFilterListeners();

    this.wahlSubscription = this.wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.kandidatenDataSource.data = [];
      this.populate();
    });
  }

  ngAfterViewInit() {
    // Paginator
    this.kandidatenDataSource.paginator = this.kandidatenTablePaginator
    this.kandidatenDataSource.sort = this.kandidatenTableSort;
  }

  resetFilters() {
    this.mandatFilter.reset("Alle");
    this.titelFilter.reset("");
    this.vornameFilter.reset("");
    this.nachnameFilter.reset("");
    this.geburtsjahrFilter.reset("");
    this.geschlechtFilter.reset("Alle");
    this.berufFilter.reset("");
    this.parteiFilter.reset("");
    this.bundeslandFilter.reset("Alle");
    this.wahlkreisFilter.reset("");
    this.relStimmenVonFilter.reset("");
    this.relStimmenBisFilter.reset("");
    this.updateFilter();
  }

  updateFilter(): void {
    this.kandidatenDataSource.filter = JSON.stringify(this.filter);
  }

  initFilterListeners(): void {
    this.mandatFilter.valueChanges.subscribe(value => {
      this.filter.mandat = value;
      this.updateFilter();
    });
    this.titelFilter.valueChanges.subscribe(value => {
      this.filter.titel = value;
      this.updateFilter();
    });
    this.vornameFilter.valueChanges.subscribe(value => {
      this.filter.vorname = value;
      this.updateFilter();
    });
    this.nachnameFilter.valueChanges.subscribe(value => {
      this.filter.nachname = value;
      this.updateFilter();
    });
    this.geburtsjahrFilter.valueChanges.subscribe(value => {
      this.filter.geburtsjahr = value ?? "";
      this.updateFilter();
    });
    this.geschlechtFilter.valueChanges.subscribe(value => {
      this.filter.geschlecht = value;
      this.updateFilter();
    });
    this.berufFilter.valueChanges.subscribe(value => {
      this.filter.beruf = value
      this.updateFilter();
    });
    this.parteiFilter.valueChanges.subscribe(value => {
      this.filter.partei = value;
      this.updateFilter();
    });
    this.bundeslandFilter.valueChanges.subscribe(value => {
      this.filter.bundesland = value;
      this.updateFilter();
    });
    this.wahlkreisFilter.valueChanges.subscribe(value => {
      this.filter.wahlkreis = value;
      this.updateFilter();
    });
    this.relStimmenVonFilter.valueChanges.subscribe(value => {
      this.filter.relStimmenVon = value ?? "";
      this.updateFilter();
    });
    this.relStimmenBisFilter.valueChanges.subscribe(value => {
      this.filter.relStimmenBis = value ?? "";
      this.updateFilter();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/${this.mdbOnly ? "mdb" : "kandidaten"}`)
      .then(response => response.json())
      .then((data: Array<Kandidat>) => {
        data = data.sort((a, b) => a.nachname.localeCompare(b.nachname));
        this.geschlechter = new Set(data.map(kandidat => kandidat.geschlecht));
        this.bundeslaender = new Set(data.filter(kandidat => kandidat.bundesland != null)
                                         .map(kandidat => kandidat.bundesland ?? ""));
        // Filter
        this.kandidatenDataSource.filterPredicate = this.filterPredicate;
        this.kandidatenDataSource.data = data;
      });
  }

  kandidatenLoaded(): boolean {
    return this.kandidatenDataSource.data != null && this.kandidatenDataSource.data.length > 0;
  }
}
