import {Component, OnDestroy, OnInit} from '@angular/core';
import {WahlSelectionService} from "../service/wahl-selection.service";
import {MatSliderChange} from '@angular/material/slider';
import { ActivationStart, Router } from '@angular/router';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent implements OnInit, OnDestroy {
  wahl !: number;
  isWahlSelectionAllowed : boolean = false;
  wahlSubscription !: Subscription;

  constructor(private readonly wahlService: WahlSelectionService, router: Router) {
    router.events.subscribe(event => {
      if (event instanceof ActivationStart) {
        const data = event.snapshot.data;
        this.isWahlSelectionAllowed = data['allowsWahlSelection'];
        if (!this.isWahlSelectionAllowed) {
          wahlService.wahlSubject.next(1);
        }
      }
    });
  }

  ngOnInit(): void {
    this.wahl = this.wahlService.wahlSubject.getValue();
    this.wahlSubscription = this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = selection;
    });
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  changeWahlSelection(event: MatSliderChange) {
    this.wahlService.wahlSubject.next(event.value!);
  }
}
