export class Ueberhang {
  bundesland: string;
  partei: string;
  partei_farbe: string;
  ueberhang: number;

  constructor(
    bundesland: string,
    partei: string,
    partei_farbe: string,
    ueberhang: number
  ) {
    this.bundesland = bundesland;
    this.partei = partei;
    this.partei_farbe = partei_farbe;
    this.ueberhang = ueberhang;
  }
}
