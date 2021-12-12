export class Wahlkreis {
  nummer: number;
  name: string;
  sieger_vorname: string;
  sieger_nachname: string;
  sieger_partei: string;
  wahlbeteiligung_prozent: number;

  constructor(
    nummer: number,
    name: string,
    sieger_vorname: string,
    sieger_nachname: string,
    sieger_partei: string,
    wahlbeteiligung_prozent: number,
  ) {
    this.nummer = nummer;
    this.name = name;
    this.sieger_vorname = sieger_vorname;
    this.sieger_nachname = sieger_nachname;
    this.sieger_partei = sieger_partei;
    this.wahlbeteiligung_prozent = wahlbeteiligung_prozent;
  }

}
