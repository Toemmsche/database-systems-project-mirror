export class Sitzverteilung {
  kuerzel: string;
  sitze: number;
  farbe: string;

  constructor(kuerzel: string, sitze: number, farbe: string) {
    this.kuerzel = kuerzel;
    this.sitze = sitze;
    this.farbe = farbe;
  }
}
