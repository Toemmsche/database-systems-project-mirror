import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {WahlkreisComponent} from "./daten/wahlkreis/wahlkreis.component";
import {UeberhangComponent} from "./stat/ueberhang/ueberhang.component";
import {StatComponent} from "./stat/stat.component";
import {KnappComponent} from "./stat/knapp/knapp.component";
import {OstenergebnisComponent} from "./stat/ostenergebnis/ostenergebnis.component";
import {StimmzettelComponent} from "./stimmabgabe/stimmzettel/stimmzettel.component";
import {MitgliederComponent} from "./bundestag/mitglieder/mitglieder.component";
import {SitzverteilungComponent} from "./bundestag/sitzverteilung/sitzverteilung.component";
import {KarteComponent} from "./karte/karte.component";
import {DatenComponent} from "./daten/daten.component";
import {StimmabgabeComponent} from "./stimmabgabe/stimmabgabe.component";
import {BundeslandComponent} from "./daten/bundesland/bundesland.component";

const routes: Routes = [
  {path: 'Bundestag', component: SitzverteilungComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Bundestag/Mitglieder', component: MitgliederComponent, pathMatch: 'full', data: { allowsWahlSelection: false }},
  {path: 'Daten', component: DatenComponent, pathMatch: 'full', data: { allowsWahlSelection: true }}, //TODO
  {path: 'Daten/Wahlkreis/:nummer', component: WahlkreisComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Daten/Bundesland/:bundesland', component: BundeslandComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Karte', component: KarteComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Statistiken', component: StatComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Statistiken/Ueberhang', component: UeberhangComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Statistiken/KnappsteSieger', component: KnappComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Statistiken/OstenErgebnis', component: OstenergebnisComponent, pathMatch: 'full', data: { allowsWahlSelection: true }},
  {path: 'Stimmabgabe', component: StimmabgabeComponent, pathMatch: 'full', data: { allowsWahlSelection: false }}, //TODO
  {path: 'Stimmabgabe/:nummer', component: StimmzettelComponent, pathMatch: 'full', data: { allowsWahlSelection: false }},
  {path: '', component: SitzverteilungComponent, pathMatch: 'full', data: { allowsWahlSelection: true }}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
