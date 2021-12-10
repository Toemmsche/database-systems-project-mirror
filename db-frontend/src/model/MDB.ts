export class MDB {

  vorname: string;
  nachname: string;
  partei: string;
  geburtsjahr: number;
  grund: string;

  constructor(vorname: string, nachname: string, partei: string, geburtsjahr: number, grund: string) {
    this.vorname = vorname;
    this.nachname = nachname;
    this.partei = partei;
    this.geburtsjahr = geburtsjahr;
    this.grund = grund;
  }
}
