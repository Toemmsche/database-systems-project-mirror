import { AfterViewInit, Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Subscription } from 'rxjs';
import { WahlSelectionService } from 'src/app/service/wahl-selection.service';
import { KnapperSiegOderNierderlage } from "../../../model/KnapperSiegOderNierderlage";
import { REST_GET } from "../../../util/ApiService";
import { MatTableDataSource } from "@angular/material/table";
import { MatPaginator } from "@angular/material/paginator";
import { FormControl } from "@angular/forms";

@Component({
  selector: 'app-knapp',
  templateUrl: './knapp.component.html',
  styleUrls: ['./knapp.component.scss']
})
export class KnappComponent implements OnInit, OnDestroy, AfterViewInit {

  wahl !: number;
  columnsToDisplay = [
    'sieger-partei',
    'verlierer-partei',
    'wahlkreis',
    'stimmen-sieger-partei',
    'stimmen-verlierer-partei',
    'differenz-stimmen',
    'differenz-relativ'
  ];

  knappDataSource: MatTableDataSource<KnapperSiegOderNierderlage> = new MatTableDataSource();

  @ViewChild('paginator')
  kandidatenTablePaginator !: MatPaginator

  typFilter = new FormControl("")
  siegerParteiFilter = new FormControl("")
  siegerParteien !: Set<string>
  verliererParteiFilter = new FormControl("")
  verliererParteien !: Set<string>

  filter = {
    typ: "Beide",
    siegerPartei: "Alle",
    verliererPartei: "Alle"
  }

  filterPredicate = (k: KnapperSiegOderNierderlage, filterJson: string) => {
    const all = "Alle"
    let filter = JSON.parse(filterJson);
    return (filter.siegerPartei === all || (k.sieger_partei === filter.siegerPartei)) &&
           (filter.verliererPartei === all || (k.verlierer_partei === filter.verliererPartei)) &&
           (filter.typ ===
            "Beide" ||
            (filter.typ === "Sieg" && k.is_sieg) ||
            (filter.typ === "Niederlage" && !k.is_sieg));
  }

  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService) {
    this.wahl = this.wahlService.getWahlNumber(wahlService.wahlSubject.getValue());
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlService.getWahlNumber(selection);
      this.knappDataSource.data = [];
      this.ngAfterViewInit();
    });
  }

  ngOnInit(): void {
    this.initFilterListeners();
  }

  ngAfterViewInit() {
    // Paginator
    this.knappDataSource.paginator = this.kandidatenTablePaginator
    this.populate();
  }

  updateFilter(): void {
    this.knappDataSource.filter = JSON.stringify(this.filter);
  }

  initFilterListeners(): void {
    this.typFilter.valueChanges.subscribe(value => {
      this.filter.typ = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.siegerParteiFilter.valueChanges.subscribe(value => {
      this.filter.siegerPartei = value;
      // emulate user filter input
      this.updateFilter();
    });
    this.verliererParteiFilter.valueChanges.subscribe(value => {
      this.filter.verliererPartei = value;
      // emulate user filter input
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
        this.siegerParteien = new Set(data.map(k => k.sieger_partei));
        this.verliererParteien = new Set(data.map(k => k.verlierer_partei));
        this.knappDataSource.filterPredicate = this.filterPredicate;
        this.knappDataSource.data = data;
      })

  }

  knappLoaded(): boolean {
    return this.knappDataSource.data != null && this.knappDataSource.data.length > 0;
  }

}
