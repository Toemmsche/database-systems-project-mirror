import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {AppComponent} from "./app.component";
import {BundestagComponent} from "./bundestag/bundestag.component";

const routes: Routes = [
  {path: 'Bundestag', component: BundestagComponent, pathMatch: 'full'},
  {path: 'Daten', component: AppComponent, pathMatch: 'full'},
  {path: 'Karte', component: AppComponent, pathMatch: 'full'},
  {path: 'Statistiken', component: AppComponent, pathMatch: 'full'},
  {path: '', component: BundestagComponent, pathMatch: 'full'}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
