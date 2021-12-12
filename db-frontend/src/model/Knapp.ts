export class Knapp {
  partei: string;
  wahlkreis_nummer: number;
  wahlkreis_name: string;
  vorsprung_prozent: number;

  constructor(
    partei: string,
    wahlkreis_nummer: number,
    wahlkreis_name: string,
    vorsprung_prozent: number
  ) {
    this.partei = partei;
    this.wahlkreis_nummer = wahlkreis_nummer;
    this.wahlkreis_name = wahlkreis_name;
    this.vorsprung_prozent = vorsprung_prozent;
  }
}
