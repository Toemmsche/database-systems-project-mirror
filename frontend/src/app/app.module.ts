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
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {MatSliderModule} from '@angular/material/slider';
import {WahlSelectionService} from './service/wahl-selection.service';
import {StimmzettelComponent} from './stimmabgabe/stimmzettel/stimmzettel.component';
import {MatRadioModule} from "@angular/material/radio";
import {MatButtonModule} from "@angular/material/button";
import {WahlkreislisteComponent} from './daten/wahlkreisliste/wahlkreisliste.component';
import {MatPaginatorModule} from "@angular/material/paginator";
import {MatFormFieldControl, MatFormFieldModule} from "@angular/material/form-field";
import {MatOptionModule} from "@angular/material/core";
import {MatSelectModule} from "@angular/material/select";
import {MatProgressSpinnerModule} from "@angular/material/progress-spinner";
import { DatenComponent } from './daten/daten.component';
import { StimmabgabeComponent } from './stimmabgabe/stimmabgabe.component';
import {MatExpansionModule} from "@angular/material/expansion";
import {MatInputModule} from "@angular/material/input";
import {MatIconModule} from "@angular/material/icon";
import { StrukturdatenComponent } from './stat/strukturdaten/strukturdaten.component';
import { SvgKarteComponent } from './karte/svg-karte/svg-karte.component';
import { BegrenzungComponent } from './daten/wahlkreisliste/begrenzung/begrenzung.component';
import { KandidatenComponent } from './daten/kandidaten/kandidaten.component';
import { BundeslandComponent } from './daten/bundesland/bundesland.component';
import { BundeslandlisteComponent } from './daten/bundeslandliste/bundeslandliste.component';
import { MatSortModule} from "@angular/material/sort";
import {MtxPopoverModule} from "@ng-matero/extensions/popover";

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
    StimmabgabeComponent,
    StrukturdatenComponent,
    SvgKarteComponent,
    BegrenzungComponent,
    KandidatenComponent,
    BundeslandComponent,
    BundeslandComponent,
    BundeslandlisteComponent
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
    MatProgressSpinnerModule,
    MatExpansionModule,
    MatInputModule,
    ReactiveFormsModule,
    MatIconModule,
    MatSortModule,
    MtxPopoverModule
  ],
  providers: [
    WahlSelectionService
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
}
