export class WahlkreisResult {
  nummer: number;
  partei: string;
  partei_farbe: string;
  abs_stimmen: number;
  rel_stimmen: number;

  constructor(
    nummer: number,
    partei: string,
    partei_farbe: string,
    abs_stimmen: number,
    rel_stimmen: number
  ) {
    this.nummer = nummer;
    this.partei = partei;
    this.partei_farbe = partei_farbe;
    this.abs_stimmen = abs_stimmen;
    this.rel_stimmen = rel_stimmen;
  }
}
