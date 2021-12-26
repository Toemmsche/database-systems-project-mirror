export class Stimmabgabe {
  wk_nummer !: number;
  erststimme !: number;
  zweitstimme !: number;


  constructor(wk_nummer: number, erststimme: number, zweitstimme: number) {
    this.wk_nummer = wk_nummer;
    this.erststimme = erststimme;
    this.zweitstimme = zweitstimme;
  }
}
