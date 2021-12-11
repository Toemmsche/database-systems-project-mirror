DROP MATERIALIZED VIEW IF EXISTS wahlkreisinformation CASCADE;
DROP MATERIALIZED VIEW IF EXISTS erststimmen_qpartei_wahlkreis_rich CASCADE;

CREATE MATERIALIZED VIEW wahlkreisinformation AS
    SELECT wk.nummer,
           wk.name,
           k.vorname                                    AS sieger_vorname,
           k.nachname                                   AS sieger_nachname,
           p.kuerzel                                    AS sieger_partei,
           SUM(ze.anzahlstimmen)::decimal / wk.deutsche AS wahlbeteiligung
    FROM wahlkreis wk,
         direktmandat dm,
         kandidat k,
         direktkandidatur dk,
         zweitstimmenergebnis ze,
         partei p
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
      AND dm.wahlkreis = wk.wkid
      AND k.kandid = dm.kandidat
      AND dm.direktid = dk.direktid
      AND dm.partei = p.parteiid
      AND ze.wahlkreis = wk.wkid
    GROUP BY wk.nummer, wk.name, k.vorname, k.nachname, p.kuerzel, wk.deutsche;


CREATE MATERIALIZED VIEW erststimmen_qpartei_wahlkreis_rich AS
    SELECT wk.nummer, p.kuerzel as partei,  p.farbe as partei_farbe, ew.abs_stimmen, ew.rel_stimmen
    FROM erststimmen_qpartei_wahlkreis ew,
         partei p,
         wahlkreis wk
    WHERE ew.partei = p.parteiid
      AND ew.wahlkreis = wk.wkid;