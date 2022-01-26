import {Component, Input, OnInit} from '@angular/core';
import {REST_GET, REST_POST} from "../../../util/ApiService";
import {StimmzettelEintrag} from "../../../model/StimmzettelEintrag";
import {ActivatedRoute} from "@angular/router";
import {MatRadioChange} from "@angular/material/radio";
import {Stimmabgabe} from "../../../model/Stimmabgabe";
import {FormControl, Validators} from "@angular/forms";
import RS, {RequestStatus} from "../../../util/RequestStatus";

@Component({
  selector: 'app-stimmzettel',
  templateUrl: './stimmzettel.component.html',
  styleUrls: ['./stimmzettel.component.scss']
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

  token = new FormControl('',
    [Validators.pattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]);

  voteStatus !: RequestStatus;
  newStimmzettelCountdown !: number;

  constructor(private route: ActivatedRoute) {
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.voteStatus = RS.IDLE;
    this.populate()
  }

  populate(): void {
    REST_GET(`20/wahlkreis/${this.nummer}/stimmzettel`)
      .then(response => response.json())
      .then((data: Array<StimmzettelEintrag>) => {
        this.stimmzettel = data;
        this.stimmzettel.splice(0,0, new StimmzettelEintrag(this.nummer, -1, -1, "", "Ungültig", -1, "Ungültig", ""));
      })
  }

  stimmzettelLoaded() {
    return this.stimmzettel != null && this.stimmzettel.length > 0;
  }

  stimmeAbgeben() {
    this.voteStatus = RS.WAITING;
    REST_POST(`20/wahlkreis/${this.nummer}/stimmabgabe`,
      new Stimmabgabe(this.nummer,
        this.token.value,
        this.erststimmeSelection ?? undefined,
        this.zweitstimmeSelection ?? undefined))
      .then(response => {
        this.voteStatus = RS.SUCCESS;
      })
      .catch(() => {
        // TODO handle error properly
        this.voteStatus = RS.FAILURE;
      }).finally(() => {
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
