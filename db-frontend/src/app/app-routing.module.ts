import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {WahlkreisComponent} from "./daten/wahlkreis/wahlkreis.component";
import {UeberhangComponent} from "./stat/ueberhang/ueberhang.component";
import {StatComponent} from "./stat/stat.component";
import {KnappComponent} from "./stat/knapp/knapp.component";
import {OstenergebnisComponent} from "./stat/ostenergebnis/ostenergebnis.component";
import {StimmzettelComponent} from "./stimmabgabe/stimmzettel/stimmzettel.component";
import {WahlkreislisteComponent} from "./daten/wahlkreisliste/wahlkreisliste.component";
import {MitgliederComponent} from "./bundestag/mitglieder/mitglieder.component";
import {SitzverteilungComponent} from "./bundestag/sitzverteilung/sitzverteilung.component";
import {KarteComponent} from "./karte/karte.component";

const routes: Routes = [
  {path: 'Bundestag', component: SitzverteilungComponent, pathMatch: 'full'},
  {path: 'Bundestag/Mitglieder', component: MitgliederComponent, pathMatch: 'full'},
  {path: 'Daten', component: WahlkreislisteComponent, pathMatch: 'full'}, //TODO
  {path: 'Daten/Wahlkreis/:nummer', component: WahlkreisComponent, pathMatch: 'full'},
  {path: 'Karte', component: KarteComponent, pathMatch: 'full'},
  {path: 'Statistiken', component: StatComponent, pathMatch: 'full'},
  {path: 'Statistiken/Ueberhang', component: UeberhangComponent, pathMatch: 'full'},
  {path: 'Statistiken/KnappsteSieger', component: KnappComponent, pathMatch: 'full'},
  {path: 'Statistiken/OstenErgebnis', component: OstenergebnisComponent, pathMatch: 'full'},
  {path: 'Stimmabgabe', redirectTo: 'Stimmabgabe/222', pathMatch: 'full'}, //TODO
  {path: 'Stimmabgabe/:nummer', component: StimmzettelComponent, pathMatch: 'full'},
  {path: '', component: SitzverteilungComponent, pathMatch: 'full'}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
