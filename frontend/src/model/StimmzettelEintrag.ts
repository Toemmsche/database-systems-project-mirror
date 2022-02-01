export class StimmzettelEintrag {
  constructor(wk_nummer: number, position: number, kandidatur: number, dk_vorname: string, dk_nachname: string, liste: number, partei: string, partei_farbe: string) {
    this.wk_nummer = wk_nummer;
    this.position = position;
    this.kandidatur = kandidatur;
    this.dk_vorname = dk_vorname;
    this.dk_nachname = dk_nachname;
    this.liste = liste;
    this.partei = partei;
    this.partei_farbe = partei_farbe;
  }

  wk_nummer !: number;
  position !: number;
  kandidatur !: number;
  dk_vorname !: string;
  dk_nachname !: string;
  liste !: number;
  partei !: string;
  partei_farbe !: string;
}
