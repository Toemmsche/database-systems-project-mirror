export class Stimmabgabe {
  wk_nummer !: number;
  erststimme !: number;
  zweitstimme !: number;
  token !: string;

  constructor(wk_nummer: number, erststimme: number, zweitstimme: number, token: string) {
    this.wk_nummer = wk_nummer;
    this.erststimme = erststimme;
    this.zweitstimme = zweitstimme;
    this.token = token;
  }
}
