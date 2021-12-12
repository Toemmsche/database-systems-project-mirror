DROP MATERIALIZED VIEW IF EXISTS wahlkreisinformation CASCADE;
DROP MATERIALIZED VIEW IF EXISTS erststimmen_qpartei_wahlkreis_rich CASCADE;

CREATE MATERIALIZED VIEW wahlkreisinformation AS
    SELECT wk.nummer,
           wk.name,
           k.vorname                                    AS sieger_vorname,
           k.nachname                                   AS sieger_nachname,
           p.kuerzel                                    AS sieger_partei,
           SUM(ze.anzahlstimmen)::decimal * 100 / wk.deutsche AS wahlbeteiligung_prozent
    FROM wahlkreis wk,
         direktmandat dm,
         kandidat k,
         zweitstimmenergebnis ze,
         partei p
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
      AND dm.wahlkreis = wk.wkid
      AND k.kandid = dm.kandidat
      AND dm.partei = p.parteiid
      AND ze.wahlkreis = wk.wkid
    GROUP BY wk.nummer, wk.name, k.vorname, k.nachname, p.kuerzel, wk.deutsche;


CREATE MATERIALIZED VIEW erststimmen_qpartei_wahlkreis_rich AS
    (SELECT wk.nummer, p.kuerzel AS partei, p.farbe AS partei_farbe, ew.abs_stimmen, ew.rel_stimmen
     FROM erststimmen_qpartei_wahlkreis ew,
          partei p,
          wahlkreis wk
     WHERE ew.partei = p.parteiid
       AND ew.wahlkreis = wk.wkid)
    UNION
    (SELECT wk.nummer, 'Sonstige', 'DDDDDD', SUM(ew.abs_stimmen) AS abs_stimmen, SUM(ew.rel_stimmen) AS rel_stimmen
     FROM erststimmen_partei_wahlkreis ew,
          partei p,
          wahlkreis wk
     WHERE ew.partei = p.parteiid
       AND ew.wahlkreis = wk.wkid
       AND p.parteiid NOT IN (SELECT * FROM qpartei)
     GROUP BY wk.nummer);