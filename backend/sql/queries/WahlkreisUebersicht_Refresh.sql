/*
UPDATE direktkandidatur
SET anzahlstimmen =
        (SELECT COUNT(*)
         FROM erststimme e
         WHERE e.kandidatur = direktid)
WHERE wahlkreis = (
    SELECT wk.wkid
    FROM wahlkreis wk
    WHERE wk.nummer = 1
      AND wk.wahl = 20
);

DELETE
FROM zweitstimmenergebnis
WHERE wahlkreis = (
    SELECT wk.wkid
    FROM wahlkreis wk
    WHERE wk.nummer = 1
      AND wk.wahl = 20
);

INSERT INTO zweitstimmenergebnis
SELECT zs.liste, zs.wahlkreis, COUNT(*)
FROM zweitstimme zs,
     wahlkreis wk
WHERE wk.wahl = 20
  AND wk.nummer = 1
  AND wk.wkid = zs.wahlkreis
GROUP BY zs.liste, zs.wahlkreis;
*/
REFRESH MATERIALIZED VIEW direktmandat;
REFRESH MATERIALIZED VIEW qpartei;


SELECT *
FROM wahlkreisinformation
WHERE wahl = 20
  AND wk_nummer = 1;

SELECT *
FROM erststimmen_qpartei_wahlkreis_rich
WHERE wahl = 20
  AND wk_nummer = 1;


SELECT *
FROM zweitstimmen_qpartei_wahlkreis_rich
WHERE wahl = 20
  AND wk_nummer = 1;
