import {AfterViewInit, Component, OnDestroy, OnInit, ViewChild} from "@angular/core";
import {Subscription} from "rxjs";
import {WahlSelectionService} from "src/app/service/wahl-selection.service";
import {KnapperSiegOderNierderlage} from "../../../model/KnapperSiegOderNierderlage";
import {REST_GET} from "../../../util/ApiService";
import {MatTableDataSource} from "@angular/material/table";
import {MatPaginator} from "@angular/material/paginator";
import {FormControl} from "@angular/forms";
import {MatSort} from "@angular/material/sort";
import {containsLowerCase} from "../../../util/ArrayHelper";

@Component({
  selector   : "app-knapp",
  templateUrl: "./knapp.component.html",
  styleUrls  : ["./knapp.component.scss"]
})
export class KnappComponent implements OnInit, OnDestroy, AfterViewInit {

  wahl !: number;
  columnsToDisplay = [
    "sieger_partei",
    "verlierer_partei",
    "wk_nummer",
    "abs_stimmen_sieger",
    "abs_stimmen_verlierer",
    "differenz_stimmen",
    "differenz_relativ"
  ];

  knappDataSource: MatTableDataSource<KnapperSiegOderNierderlage> = new MatTableDataSource();

  @ViewChild("paginator")
  knappTablePaginator !: MatPaginator;
  @ViewChild(MatSort)
  knappTableSort !: MatSort;

  typFilter = new FormControl("Beide")

  siegerParteiFilter = new FormControl("")
  verliererParteiFilter = new FormControl("")

  filter = {
    typ            : "Beide",
    siegerPartei   : "",
    verliererPartei: ""
  }

  filterPredicate = (k: KnapperSiegOderNierderlage, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.siegerPartei === all || containsLowerCase(k.sieger_partei, filter.siegerPartei)) &&
      (filter.verliererPartei === "" || containsLowerCase(k.verlierer_partei, filter.verliererPartei)) &&
      (filter.typ ===
        "Beide" ||
        (filter.typ === "Sieg" && k.is_sieg) ||
        (filter.typ === "Niederlage" && !k.is_sieg));
  }

  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {}

  ngOnInit(): void {
    this.initFilterListeners();
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.knappDataSource.data = [];
      this.populate();
    });
  }

  ngAfterViewInit() {
    // Paginator
    this.knappDataSource.paginator = this.knappTablePaginator
    this.knappDataSource.sort = this.knappTableSort;
    this.knappDataSource.sortingDataAccessor = (k, property) => {
      switch (property) {
        case "differenz_relativ":
          return 100 * k.differenz_stimmen / (k.is_sieg ? k.abs_stimmen_verlierer : k.abs_stimmen_sieger);
        default:
          // @ts-ignore
          return k[property];
      };
    }
  }

  resetFilters() {
    this.typFilter.reset("Beide");
    this.siegerParteiFilter.reset("");
    this.verliererParteiFilter.reset("");
  }

  updateFilter(): void {
    this.knappDataSource.filter = JSON.stringify(this.filter);
  }

  initFilterListeners(): void {
    this.typFilter.valueChanges.subscribe(value => {
      this.filter.typ = value;
      this.updateFilter();
    });
    this.siegerParteiFilter.valueChanges.subscribe(value => {
      this.filter.siegerPartei = value;
      this.updateFilter();
    });
    this.verliererParteiFilter.valueChanges.subscribe(value => {
      this.filter.verliererPartei = value;
      this.updateFilter();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/stat/knapp`)
      .then(response => response.json())
      .then((data: Array<KnapperSiegOderNierderlage>) => {
        data = data.sort((a, b) => {
          return a.differenz_stimmen - b.differenz_stimmen;
        })
        this.knappDataSource.filterPredicate = this.filterPredicate;
        this.knappDataSource.data = data;
      })

  }

  knappLoaded(): boolean {
    return this.knappDataSource.data != null && this.knappDataSource.data.length > 0;
  }


}
