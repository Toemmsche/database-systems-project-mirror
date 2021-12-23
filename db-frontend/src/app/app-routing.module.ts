import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {BundestagComponent} from "./bundestag/bundestag.component";
import {WahlkreisComponent} from "./daten/wahlkreis/wahlkreis.component";
import {WahlkreissiegerComponent} from "./karte/wahlkreissieger/wahlkreissieger.component";
import {UeberhangComponent} from "./stat/ueberhang/ueberhang.component";
import {StatComponent} from "./stat/stat.component";
import {KnappComponent} from "./stat/knapp/knapp.component";
import {OstenergebnisComponent} from "./stat/ostenergebnis/ostenergebnis.component";
import {StimmzettelComponent} from "./stimmabgabe/stimmzettel/stimmzettel.component";

const routes: Routes = [
  {path: 'Bundestag', component: BundestagComponent, pathMatch: 'full'},
  {path: 'Daten', redirectTo: 'Daten/Wahlkreis/42', pathMatch: 'full'}, //TODO
  {path: 'Daten/Wahlkreis/:nummer', component: WahlkreisComponent, pathMatch: 'full'},
  {path: 'Karte', component: WahlkreissiegerComponent, pathMatch: 'full'},
  {path: 'Statistiken', component: StatComponent, pathMatch: 'full'},
  {path: 'Statistiken/Ueberhang', component: UeberhangComponent, pathMatch: 'full'},
  {path: 'Statistiken/KnappsteSieger', component: KnappComponent, pathMatch: 'full'},
  {path: 'Statistiken/OstenErgebnis', component: OstenergebnisComponent, pathMatch: 'full'},
  {path: 'Stimmabgabe', redirectTo: 'Stimmabgabe/222', pathMatch: 'full'}, //TODO
  {path: 'Stimmabgabe/:nummer', component: StimmzettelComponent, pathMatch: 'full'},
  {path: '', component: BundestagComponent, pathMatch: 'full'}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
