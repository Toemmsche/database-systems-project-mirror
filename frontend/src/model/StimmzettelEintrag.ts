export class StimmzettelEintrag {
  constructor(wk_nummer: number, position: number, hat_landesliste: boolean, kandidatur: number, dk_vorname: string, dk_nachname: string, liste: number, partei: string, partei_lang: string, partei_farbe: string) {
    this.wk_nummer = wk_nummer;
    this.position = position;
    this.hat_landesliste = hat_landesliste;
    this.kandidatur = kandidatur;
    this.dk_vorname = dk_vorname;
    this.dk_nachname = dk_nachname;
    this.liste = liste;
    this.partei = partei;
    this.partei_lang = partei_lang;
    this.partei_farbe = partei_farbe;
  }

  wk_nummer !: number;
  position !: number;
  hat_landesliste !: boolean;
  kandidatur !: number;
  dk_vorname !: string;
  dk_nachname !: string;
  liste !: number;
  partei !: string;
  partei_lang !: string;
  partei_farbe !: string;
}
