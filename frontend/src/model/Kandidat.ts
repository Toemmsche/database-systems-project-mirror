export default class Kandidat {
  ist_einzug !: boolean;
  ist_direktmandat ?: boolean;
  titel !: string;
  vorname !: string;
  nachname !: string;
  geburtsjahr !: number;
  geschlecht !: string;
  beruf !: string;
  ist_einzelbewerbung !: boolean;
  partei !: string;
  partei_lang !: string;
  partei_farbe !: string;
  bundesland ?: string;
  listenplatz ?: number;
  wk_nummer ?: number;
  wk_name ?: string;
  rel_erststimmen ?: number;
}
