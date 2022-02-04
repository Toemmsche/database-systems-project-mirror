import {AfterViewInit, Component, Input, OnInit, ViewChild} from "@angular/core";
import {Subscription} from "rxjs";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import Kandidat from "../../../model/Kandidat";
import {REST_GET} from "../../../util/ApiService";
import {MatTableDataSource} from "@angular/material/table";
import {MatPaginator} from "@angular/material/paginator";
import {FormControl} from "@angular/forms";

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
    "partei",
    "geburtsjahr",
    "geschlecht",
    "beruf",
    "partei",
    "bundesland",
    "listenplatz",
    "wahlkreis",
    "erststimmenanteil"
  ];

  kandidatenDataSource: MatTableDataSource<Kandidat> = new MatTableDataSource();

  @ViewChild("paginator")
  kandidatenTablePaginator !: MatPaginator

  titelFilter = new FormControl("");

  vornameFilter = new FormControl("");

  nachnameFilter = new FormControl("");

  geburtsjahrFilter = new FormControl("");

  geschlechter !: Set<string>
  geschlechtFilter = new FormControl("");

  berufFilter = new FormControl("");

  parteiFilter = new FormControl("");

  mandatFilter = new FormControl("")

  bundeslaender !: Set<string>
  bundeslandFilter = new FormControl("");

  wahlkreisFilter = new FormControl("");

  erststimmenAnteilFilter = new FormControl("");

  filter = {
    titel      : "",
    vorname    : "",
    nachname   : "",
    geburtsjahr: "",
    geschlecht : "Alle",
    beruf      : "",
    partei     : "",
    mandat     : "Alle",
    bundesland : "Alle",
    wahlkreis  : "",
  }

  filterPredicate = (k: Kandidat, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.vorname === "" || k.vorname.indexOf(filter.vorname) !== -1) &&
      (filter.nachname === "" || k.nachname.indexOf(filter.nachname) !== -1) &&
      (filter.geburtsjahr ===
        "" ||
        k.geburtsjahr !=
        null &&
        k.geburtsjahr.toString().indexOf(filter.geburtsjahr.toString()) !==
        -1) &&
      (filter.geschlecht === all || k.geschlecht === filter.geschlecht) &&
      (filter.beruf === "" || k.beruf.toLowerCase().indexOf(filter.beruf) !== -1) &&
      (filter.partei === "" || k.partei.toLowerCase().indexOf(filter.partei) !== -1) &&
      (filter.mandat === all || (filter.mandat === "MDB" && k.ist_einzug) ||
        (filter.mandat === "Direktmandat" && k.ist_einzug && k.ist_direktmandat) ||
        (filter.mandat === "Listenmandat" && k.ist_einzug && !k.ist_direktmandat)) &&
      (filter.bundesland === all || k.bundesland === filter.bundesland) &&

      (filter.titel === "" || k.titel.toLowerCase().indexOf(filter.titel) !== -1) &&
      (filter.wahlkreis === "" || (k.wk_nummer + "-" + k.wk_name).toLowerCase().indexOf(filter.wahlkreis) !== -1);
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
    this.titelFilter.valueChanges.subscribe(value => {
      this.filter.titel = value.toLowerCase();
      // emulate user filter input
      this.updateFilter();
    });
    this.vornameFilter.valueChanges.subscribe(value => {
      this.filter.vorname = value.toLowerCase();
      // emulate user filter input
      this.updateFilter();
    });
    this.nachnameFilter.valueChanges.subscribe(value => {
      this.filter.nachname = value.toLowerCase();
      // emulate user filter input
      this.updateFilter();
    });
    this.geburtsjahrFilter.valueChanges.subscribe(value => {
      this.filter.geburtsjahr = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.geschlechtFilter.valueChanges.subscribe(value => {
      this.filter.geschlecht = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.berufFilter.valueChanges.subscribe(value => {
      this.filter.beruf = value.toLowerCase()
      // emulate user filter input
      this.updateFilter();
    });
    this.parteiFilter.valueChanges.subscribe(value => {
      this.filter.partei = value.toLowerCase();
      // emulate user filter input
      this.updateFilter();
    });
    this.bundeslandFilter.valueChanges.subscribe(value => {
      this.filter.bundesland = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.wahlkreisFilter.valueChanges.subscribe(value => {
      this.filter.wahlkreis = value.toLowerCase();
      // emulate user filter input
      this.updateFilter();
    });
    this.erststimmenAnteilFilter.valueChanges.subscribe(value => {
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
        if (this.mdbOnly) {
          data = data.filter(k => k.ist_einzug);
        }
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
