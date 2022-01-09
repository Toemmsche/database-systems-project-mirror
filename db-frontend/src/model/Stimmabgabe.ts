export class Stimmabgabe {
  wk_nummer !: number;
  erststimme ?: number;
  zweitstimme ?: number;
  token !: string;

  constructor(wk_nummer: number, token: string, erststimme?: number, zweitstimme?: number,) {
    this.wk_nummer = wk_nummer;
    this.erststimme = erststimme;
    this.zweitstimme = zweitstimme;
    this.token = token;
  }
}
