import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';
import {AppComponent} from "./app.component";

const routes: Routes = [
  {path: 'Bundestag', component: AppComponent, pathMatch: 'full'},
  {path: 'Daten', component: AppComponent, pathMatch: 'full'},
  {path: 'Karte', component: AppComponent, pathMatch: 'full'},
  {path: 'Statistiken', component: AppComponent, pathMatch: 'full'},
  {path: '', component: AppComponent, pathMatch: 'full'}
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {

}
