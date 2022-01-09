import {Component, Input, OnInit} from '@angular/core';
import {REST_GET, REST_POST} from "../../../util";
import {StimmzettelEintrag} from "../../../model/StimmzettelEintrag";
import {ActivatedRoute, Router} from "@angular/router";
import {MatRadioChange} from "@angular/material/radio";
import {Stimmabgabe} from "../../../model/Stimmabgabe";
import {FormControl, Validators} from "@angular/forms";

@Component({
  selector   : 'app-stimmzettel',
  templateUrl: './stimmzettel.component.html',
  styleUrls  : ['./stimmzettel.component.scss']
})
export class StimmzettelComponent implements OnInit {

  @Input()
  nummer !: number;
  // direktID
  erststimmeSelection !: number;
  // listenID
  zweitstimmeSelection !: number;
  stimmzettel !: Array<StimmzettelEintrag>;

  columnsToDisplay = ['erststimme_selection', 'erststimme', 'zweitstimme', 'zweitstimme_selection']

  token = new FormControl('', [Validators.pattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]);

  showResponse !: boolean;
  voteSuccessful !: boolean | null;
  newStimmzettelCountdown !: number;

  constructor(private route: ActivatedRoute) {
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.showResponse = false;
    this.voteSuccessful = true;
    this.populate()
  }

  populate(): void {
    REST_GET(`20/wahlkreis/${this.nummer}/stimmzettel`)
      .then(response => response.json())
      .then((data: Array<StimmzettelEintrag>) => {
        this.stimmzettel = data;
      })
  }

  stimmzettelLoaded() {
    return this.stimmzettel != null && this.stimmzettel.length > 0;
  }


  stimmeAbgeben() {
    this.voteSuccessful = null;
    this.showResponse = true;
    REST_POST(`20/wahlkreis/${this.nummer}/stimmabgabe`,
      new Stimmabgabe(this.nummer, this.token.value, this.erststimmeSelection ?? undefined, this.zweitstimmeSelection ?? undefined))
      .then(response => {
        this.voteSuccessful = response.status === 200;
        this.newStimmzettelCountdown = 10;
        setInterval(() => {
          if (this.newStimmzettelCountdown > 0) {
            this.newStimmzettelCountdown--;
          } else {
            this.resetStimmzettel();
          }
        }, 1000);
      })
  }

  resetStimmzettel(): void {
    this.showResponse = false;
    // Ugly way to reload page
    window.location.reload();
  }

  erststimmeChanged(event: MatRadioChange) {
    this.erststimmeSelection = parseInt(event.source.id.split("_")[1])
  }

  zweitstimmeChanged(event: MatRadioChange) {
    this.zweitstimmeSelection = parseInt(event.source.id.split("_")[1])
  }
}
