export class Begrenzung {
  nummer: number;
  name: string;
  wahl: number;
  begrenzung: string;

  constructor(
    nummer: number,
    wahl: number,
    name: string,
    begrenzung: string
  ) {
    this.nummer = nummer;
    this.name = name;
    this.wahl = wahl;
    this.begrenzung = begrenzung;
  }
}
