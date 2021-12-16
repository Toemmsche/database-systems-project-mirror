DROP VIEW IF EXISTS wahlkreissieger_zweitstimme CASCADE;
DROP VIEW IF EXISTS wahlkreissieger_erststimme CASCADE;
DROP VIEW IF EXISTS wahlkreissieger CASCADE;

CREATE VIEW wahlkreissieger_zweitstimme(wahl, wahlkreis, partei) AS
    WITH zweitstimmenergebnis_nummeriert(platz, wahl, wahlkreis, partei) AS (
        SELECT ROW_NUMBER() OVER (PARTITION BY ll.wahl, ze.wahlkreis ORDER BY ze.anzahlstimmen DESC) AS platz,
               ll.wahl,
               ze.wahlkreis,
               ll.partei
        FROM zweitstimmenergebnis ze,
             landesliste ll
        WHERE ll.listenid = ze.liste)

    SELECT ze.wahl,
           ze.wahlkreis,
           ze.partei
    FROM zweitstimmenergebnis_nummeriert ze
    WHERE ze.platz = 1;

CREATE VIEW wahlkreissieger_erststimme(wahl, wahlkreis, partei) AS
    SELECT wk.wahl,
           wk.wkid AS wahlkreis,
           dm.partei
    FROM wahlkreis wk,
         direktmandat dm
    WHERE wk.wkid = dm.wahlkreis;


CREATE VIEW wahlkreissieger(wahl, wk_nummer, wk_name, erststimme_sieger, erststimme_sieger_farbe, zweitstimme_sieger, zweitstimme_sieger_farbe) AS
    SELECT we.wahl,
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
      AND we.wahl = wz.wahl
      AND we.wahlkreis = wz.wahlkreis
      AND pe.parteiid = we.partei
      AND pz.parteiid = wz.partei
