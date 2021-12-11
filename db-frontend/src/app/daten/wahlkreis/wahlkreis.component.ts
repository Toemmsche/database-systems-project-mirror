import {Component, Input, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {REST_GET} from "../../../util";
import {MDB} from "../../../model/MDB";
import {Wahlkreis} from "../../../model/Walhkreis";

@Component({
  selector: 'app-wahlkreis',
  templateUrl: './wahlkreis.component.html',
  styleUrls: ['./wahlkreis.component.scss']
})
export class WahlkreisComponent implements OnInit {

  @Input()
  nummer !: number;
  wahlkreis !: Wahlkreis;

  constructor(private route: ActivatedRoute) {
  }

  ngOnInit(): void {
    // Get wahlkreis nummer
    this.nummer = parseInt(<string>this.route.snapshot.paramMap.get('nummer'));
    this.populate();
  }

  populate(): void {
    REST_GET(`20/wahlkreis/${this.nummer}`)
      .then(response => response.json())
      .then((data: Wahlkreis) => {
        this.wahlkreis = data;
        console.log(data);
      });
  }

  wahlkreisLoaded(): boolean {
    return this.wahlkreis != null;
  }

}
