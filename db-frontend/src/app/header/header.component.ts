import {Component, OnInit} from '@angular/core';
import {WahlSelectionService} from "../service/wahl-selection.service";
import {MatSliderChange} from '@angular/material/slider';
import { ActivationEnd, Router } from '@angular/router';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent implements OnInit {
  wahl !: number;
  isWahlSelectionAllowed : boolean = false;

  constructor(private readonly wahlService: WahlSelectionService, router: Router) {
    router.events.subscribe(event => {
      if (event instanceof ActivationEnd) {
        const data = event.snapshot.data;
        this.isWahlSelectionAllowed = data['allowsWahlSelection'];
      }
    });
  }

  ngOnInit(): void {
    this.wahl = this.wahlService.wahlSubject.getValue();
    this.wahlService.wahlSubject.subscribe((selection: number) => {
      this.wahl = selection;
    });
  }

  changeWahlSelection(event: MatSliderChange) {
    this.wahlService.wahlSubject.next(event.value!);
  }
}
