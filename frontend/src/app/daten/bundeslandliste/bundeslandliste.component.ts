import {Component, Input, OnInit} from "@angular/core";
import {Wahlkreis} from "../../../model/Walhkreis";
import {Subscription} from "rxjs";
import {WahlSelectionService} from "../../service/wahl-selection.service";
import {REST_GET} from "../../../util/ApiService";
import Bundesland from "../../../model/Bundesland";

@Component({
  selector: 'app-bundeslandliste',
  templateUrl: './bundeslandliste.component.html',
  styleUrls: ['./bundeslandliste.component.scss']
})
export class BundeslandlisteComponent implements OnInit {

  @Input()
  routePrefix !: string;

  wahl !: number;
  bundeslaender !: Array<Bundesland>;
  private wahlSubscription: Subscription;

  constructor(private readonly wahlservice: WahlSelectionService) {
    this.wahl = this.wahlservice.getWahlNumber(wahlservice.wahlSubject.getValue());
    this.wahlSubscription = wahlservice.wahlSubject.subscribe((selection: number) => {
      this.wahl = this.wahlservice.getWahlNumber(selection);
      this.bundeslaender= []
      this.ngOnInit()
    });
  }

  ngOnInit(): void {
    this.populate()
  }

  ngOnDestroy(): void {
    this.wahlSubscription.unsubscribe();
  }

  populate(): void {
    REST_GET(`${this.wahl}/bundesland`)
      .then(response => response.json())
      .then((data: Array<Bundesland>) => {
        this.bundeslaender = data.sort((a, b) => a.name.localeCompare(b.name));
      })
  }


  bundeslaenderLoaded() {
    return this.bundeslaender != null && this.bundeslaender.length > 0;
  }
}
