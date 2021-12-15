DROP INDEX IF EXISTS erststimme_kandidatur;
DROP INDEX IF EXISTS zweitstimme_wahlkreis;
DROP INDEX IF EXISTS zweitstimme_liste;
DROP INDEX IF EXISTS zweitstimme_wahlkreis_liste;

DELETE
FROM erststimme;
DELETE
FROM zweitstimme;

--Erststimmen
WITH stimmen AS (
    SELECT dk.*, GENERATE_SERIES(1, dk.anzahlstimmen) FROM direktkandidatur dk
)
INSERT
INTO erststimme (kandidatur)
        (SELECT s.direktid FROM stimmen s);

--Index
CREATE INDEX erststimme_kandidatur ON erststimme (kandidatur);


--Zweitstimmen
WITH stimmen AS
         (SELECT zse.*, GENERATE_SERIES(1, zse.anzahlstimmen) FROM zweitstimmenergebnis zse)
INSERT
INTO zweitstimme (liste, wahlkreis)
        (SELECT s.liste, s.wahlkreis FROM stimmen s);

--Indizes
CREATE INDEX zweitstimme_wahlkreis ON zweitstimme (wahlkreis);
CREATE INDEX zweitstimme_liste ON zweitstimme (liste);
CREATE INDEX zweitstimme_wahlkreis_liste ON zweitstimme (wahlkreis, liste);