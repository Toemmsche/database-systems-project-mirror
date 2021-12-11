export class Sitzverteilung {
  partei: string;
  sitze: number;
  partei_farbe: string;

  constructor(partei: string, sitze: number, partei_farbe: string) {
    this.partei = partei;
    this.sitze = sitze;
    this.partei_farbe = partei_farbe;
  }
}
