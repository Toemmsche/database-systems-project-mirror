export class Wahlkreissieger {


  constructor(
    nummer: number,
    name: string,
    erststimme_sieger: string,
    erststimme_sieger_farbe: string,
    zweitstimme_sieger: string,
    zweitstimme_sieger_farbe: string
  ) {
    this.nummer = nummer;
    this.name = name;
    this.erststimme_sieger = erststimme_sieger;
    this.erststimme_sieger_farbe = erststimme_sieger_farbe;
    this.zweitstimme_sieger = zweitstimme_sieger;
    this.zweitstimme_sieger_farbe = zweitstimme_sieger_farbe;
  }

  nummer: number;
  name: string;
  erststimme_sieger: string;
  erststimme_sieger_farbe: string;
  zweitstimme_sieger: string;
  zweitstimme_sieger_farbe: string;

}
