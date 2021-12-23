import {Component, Input, OnInit} from '@angular/core';
import {REST_GET} from "../../../util";
import {StimmzettelEintrag} from "../../../model/StimmzettelEintrag";
import {ActivatedRoute} from "@angular/router";

@Component({
  selector: 'app-stimmzettel',
  templateUrl: './stimmzettel.component.html',
  styleUrls: ['./stimmzettel.component.scss']
})
export class StimmzettelComponent implements OnInit {

  @Input()
  nummer !: number;
  stimmzettel !: Array<StimmzettelEintrag>

  columnsToDisplay = ['erststimme_selection', 'erststimme', 'zweitstimme', 'zweitstimme_selection']

  constructor(private route: ActivatedRoute) {
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.populate()
  }

  populate(): void {
    REST_GET(`20/wahlkreis/${this.nummer}/stimmzettel`)
      .then(response => response.json())
      .then((data: Array<StimmzettelEintrag>) => {
        this.stimmzettel = data;
        console.log(this.stimmzettel)
      })
  }

  stimmzettelLoaded() {
    return this.stimmzettel != null && this.stimmzettel.length > 0;
  }

}
