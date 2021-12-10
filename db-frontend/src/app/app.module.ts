import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';

import {AppRoutingModule} from './app-routing.module';
import {AppComponent} from './app.component';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {MatToolbarModule} from '@angular/material/toolbar';
import {NavitemComponent} from './header/navigation/navitem/navitem.component';
import {SitzverteilungComponent} from './bundestag/sitzverteilung/sitzverteilung.component';
import {HeaderComponent} from './header/header.component';
import {FooterComponent} from './footer/footer.component';
import {BundestagComponent} from './bundestag/bundestag.component';
import {ChartModule} from 'angular2-chartjs';
import {MatTableModule} from "@angular/material/table";

@NgModule({
  declarations: [
    AppComponent,
    NavitemComponent,
    SitzverteilungComponent,
    HeaderComponent,
    FooterComponent,
    BundestagComponent

  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    MatToolbarModule,
    ChartModule,
    MatTableModule,
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {
}
