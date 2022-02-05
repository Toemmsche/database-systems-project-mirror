import {Component, OnDestroy, OnInit} from '@angular/core';
import {REST_GET} from "../../../util/ApiService";
import {Sitzverteilung} from "../../../model/Sitzverteilung";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import { Subscription } from 'rxjs';

@Component({
  selector   : 'app-sitzverteilung',
  templateUrl: './sitzverteilung.component.html',
  styleUrls  : ['./sitzverteilung.component.scss']
})
export class SitzverteilungComponent implements OnInit, OnDestroy {

  wahl !: number;
  wahlSubscription !: Subscription;

  sitzverteilung !: Array<Sitzverteilung>;
  sitzVerteilungConfig = {
    type   : 'doughnut',
    data   : {
      labels  : [] as Array<string>,
      datasets: [
        {
          label          : "Sitze",
          hoverOffset    : 4,
          data           : [] as Array<number>,
          backgroundColor: [] as Array<string>,
        }
      ]
    },
    options: {
      rotation           : Math.PI,
      circumference      : Math.PI,
      responsive         : true,
      maintainAspectRatio: true
    }
  }

  constructor(private readonly wahlservice: WahlSelectionService) {}

  ngOnInit(): void {
    this.wahlSubscription = this.wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.sitzverteilung = [];
      this.populate();
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate() {
    REST_GET(`${this.wahl}/sitzverteilung`)
      .then(response => response.json())
      .then((data: Array<Sitzverteilung>) => {
        // Populate half-pie chart
        const chartData = this.sitzVerteilungConfig.data;
        chartData.labels = data.map((row) => row.partei);
        chartData.datasets[0].data = data.map((row) => row.sitze);
        chartData.datasets[0].backgroundColor = data.map((row) => '#' +
          row.partei_farbe);

        this.sitzVerteilungConfig.data = Object.assign({}, chartData)

        // Save for later
        this.sitzverteilung = data;
      });
  }

  sitzVerteilungLoaded() {
    return this.sitzverteilung != null && this.sitzverteilung.length > 0;
  }

  getSitzeDiff(sv: Sitzverteilung): string {
    const diff = sv.sitze - sv.sitze_vor;
    const diffText = `(${diff > 0 ? '+' : ''}${diff})`;
    return diffText;
  }

  getSitzeRelDiff(sv: Sitzverteilung): string {
    const diff = 100 * (sv.sitze_rel - sv.sitze_vor_rel);
    const diffText = `(${diff > 0 ? '+' : ''}${diff.toFixed(2)}%)`;
    return diffText;
  }

  getSitzeDiffClass(sv: Sitzverteilung): string {
    const diff = sv.sitze - sv.sitze_vor;
    if (Math.abs(diff) < 0.0000001) {
      return 'stimmen-diff-neutral';
    } else if (diff > 0) {
      return 'stimmen-diff-pos';
    } else {
      return 'stimmen-diff-neg';
    }
  }

  getSitzeBundestag(): number {
    return this.sitzverteilung.filter(s => s.sitze).reduce((prev, curr) => prev + curr.sitze, 0);
  }

  getSitzeBundestagDiff(): number {
    const sitzeVor = this.sitzverteilung.filter(s => s.sitze_vor).reduce((prev, curr) => prev + curr.sitze_vor, 0);
    const diff = this.getSitzeBundestag() - sitzeVor;
    return diff;
  }

  getSitzeBundestagDiffText(): string {
    const diff = this.getSitzeBundestagDiff();
    const diffText = `(${diff > 0 ? '+' : ''}${diff})`;
    return diffText;
  }

  hasVorperiode(): boolean {
    return this.sitzverteilung.some(s => s.sitze_vor != null);
  }

  getSitzeGesamtDiffClass(): string {
    const diff = this.getSitzeBundestagDiff();
    if (Math.abs(diff) < 0.0000001) {
      return 'stimmen-diff-neutral';
    } else if (diff > 0) {
      return 'stimmen-diff-pos';
    } else {
      return 'stimmen-diff-neg';
    }
  }
}
