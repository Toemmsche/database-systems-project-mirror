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
import {MitgliederComponent} from './bundestag/mitglieder/mitglieder.component';
import {WahlkreisComponent} from './daten/wahlkreis/wahlkreis.component';
import {MatCardModule} from "@angular/material/card";
import {CommonModule} from "@angular/common";
import { WahlkreissiegerComponent } from './karte/wahlkreissieger/wahlkreissieger.component';
import { UeberhangComponent } from './stat/ueberhang/ueberhang.component';
import {MatDividerModule} from "@angular/material/divider";
import { StatComponent } from './stat/stat.component';
import {MatListModule} from "@angular/material/list";
import {MatGridListModule} from "@angular/material/grid-list";
import { KnappComponent } from './stat/knapp/knapp.component';

@NgModule({
  declarations: [
    AppComponent,
    NavitemComponent,
    SitzverteilungComponent,
    HeaderComponent,
    FooterComponent,
    BundestagComponent,
    MitgliederComponent,
    WahlkreisComponent,
    WahlkreissiegerComponent,
    UeberhangComponent,
    StatComponent,
    KnappComponent

  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    MatToolbarModule,
    ChartModule,
    MatTableModule,
    MatCardModule,
    CommonModule,
    MatDividerModule,
    MatListModule,
    MatGridListModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {
}
