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
import {MatTableModule} from "@angular/material/table";
import {MitgliederComponent} from './bundestag/mitglieder/mitglieder.component';
import {WahlkreisComponent} from './daten/wahlkreis/wahlkreis.component';
import {MatCardModule} from "@angular/material/card";
import {CommonModule} from "@angular/common";
import {UeberhangComponent} from './stat/ueberhang/ueberhang.component';
import {MatDividerModule} from "@angular/material/divider";
import {StatComponent} from './stat/stat.component';
import {MatListModule} from "@angular/material/list";
import {MatGridListModule} from "@angular/material/grid-list";
import {KnappComponent} from './stat/knapp/knapp.component';
import {OstenergebnisComponent} from './stat/ostenergebnis/ostenergebnis.component';
import {MatSlideToggleModule} from "@angular/material/slide-toggle";
import {ChartModule} from "angular2-chartjs";
import {KarteComponent} from './karte/karte.component';
import {MatButtonToggleModule} from '@angular/material/button-toggle';
import {FormsModule} from '@angular/forms';
import {MatSliderModule} from '@angular/material/slider';
import {WahlSelectionService} from './service/wahl-selection.service';
import {StimmzettelComponent} from './stimmabgabe/stimmzettel/stimmzettel.component';
import {MatRadioModule} from "@angular/material/radio";
import {MatButtonModule} from "@angular/material/button";
import {WahlkreislisteComponent} from './daten/wahlkreisliste/wahlkreisliste.component';
import {MatPaginatorModule} from "@angular/material/paginator";
import {MatFormFieldModule} from "@angular/material/form-field";
import {MatOptionModule} from "@angular/material/core";
import {MatSelectModule} from "@angular/material/select";
import {MatProgressSpinnerModule} from "@angular/material/progress-spinner";
import { DatenComponent } from './daten/daten.component';
import { StimmabgabeComponent } from './stimmabgabe/stimmabgabe.component';

@NgModule({
  declarations: [
    AppComponent,
    NavitemComponent,
    SitzverteilungComponent,
    HeaderComponent,
    FooterComponent,
    MitgliederComponent,
    WahlkreisComponent,
    UeberhangComponent,
    StatComponent,
    KnappComponent,
    OstenergebnisComponent,
    KarteComponent,
    StimmzettelComponent,
    WahlkreislisteComponent,
    DatenComponent,
    StimmabgabeComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    FormsModule,
    MatToolbarModule,
    ChartModule,
    MatTableModule,
    MatCardModule,
    CommonModule,
    MatDividerModule,
    MatListModule,
    MatGridListModule,
    MatSlideToggleModule,
    MatButtonToggleModule,
    MatSliderModule,
    MatRadioModule,
    MatButtonModule,
    MatPaginatorModule,
    MatFormFieldModule,
    MatOptionModule,
    MatSelectModule,
    MatProgressSpinnerModule
  ],
  providers: [
    WahlSelectionService
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
}
