import {Component, Inject, OnInit} from '@angular/core';
import {WahlSelectionService} from "../service/wahl-selection.service";
import {MatSlideToggleChange} from "@angular/material/slide-toggle";

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent implements OnInit {

  wahlService !: WahlSelectionService

  constructor(private ws: WahlSelectionService) {
    this.wahlService = ws;
  }

  ngOnInit(): void {
  }

  changeWahlSelection(event: MatSlideToggleChange) {
    this.wahlService.wahlSubject.next(event.checked)
  }
}
