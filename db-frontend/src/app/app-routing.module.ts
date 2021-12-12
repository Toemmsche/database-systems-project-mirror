import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {AppComponent} from "./app.component";
import {BundestagComponent} from "./bundestag/bundestag.component";
import {WahlkreisComponent} from "./daten/wahlkreis/wahlkreis.component";
import {WahlkreissiegerComponent} from "./karte/wahlkreissieger/wahlkreissieger.component";

const routes: Routes = [
  {path: 'Bundestag', component: BundestagComponent, pathMatch: 'full'},
  {path: 'Daten', redirectTo: 'Daten/Wahlkreis/42', pathMatch: 'full'},
  {path: 'Daten/Wahlkreis/:nummer', component: WahlkreisComponent, pathMatch: 'full'},
  {path: 'Karte', component: WahlkreissiegerComponent, pathMatch: 'full'},
  {path: 'Statistiken', component: BundestagComponent, pathMatch: 'full'},
  {path: '', component: BundestagComponent, pathMatch: 'full'}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
