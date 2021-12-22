DROP VIEW IF EXISTS wahlkreissieger_zweitstimme CASCADE;
DROP VIEW IF EXISTS wahlkreissieger_erststimme CASCADE;
DROP VIEW IF EXISTS wahlkreissieger CASCADE;

CREATE VIEW wahlkreissieger_zweitstimme(wahlkreis, partei) AS
    WITH zweitstimmenergebnis_nummeriert(wahlkreis, partei, wk_rang) AS (
        SELECT ze.wahlkreis,
               ll.partei,
               ROW_NUMBER() OVER (PARTITION BY ze.wahlkreis ORDER BY ze.anzahlstimmen DESC) AS wk_rang
        FROM zweitstimmenergebnis ze,
             landesliste ll
        WHERE ll.listenid = ze.liste)
    SELECT ze.wahlkreis,
           ze.partei
    FROM zweitstimmenergebnis_nummeriert ze
    WHERE ze.wk_rang = 1;

CREATE VIEW wahlkreissieger_erststimme(wahlkreis, partei) AS
    SELECT m.wahlkreis, m.partei
    FROM mandat m
    WHERE m.ist_direktmandat;


CREATE VIEW wahlkreissieger
            (wahl, wk_nummer, wk_name, erststimme_sieger, erststimme_sieger_farbe, zweitstimme_sieger,
             zweitstimme_sieger_farbe)
AS
    SELECT wk.wahl,
           wk.nummer,
           wk.name,
           we.partei AS erststimme_sieger,
           pe.farbe  AS erststimme_sieger_farbe,
           wz.partei AS zweitstimme_sieger,
           pz.farbe  AS zweitstimme_sieger_farbe
    FROM wahlkreissieger_erststimme we,
         wahlkreissieger_zweitstimme wz,
         wahlkreis wk,
         partei pe,
         partei pz
    WHERE wk.wkid = we.wahlkreis
      AND wk.wkid = wz.wahlkreis
      AND pe.parteiid = we.partei
      AND pz.parteiid = wz.partei
