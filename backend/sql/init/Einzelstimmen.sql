DROP INDEX IF EXISTS erststimme_kandidatur;

DROP INDEX IF EXISTS zweitstimme_wahlkreis;
DROP INDEX IF EXISTS zweitstimme_liste;
DROP INDEX IF EXISTS zweitstimme_wahlkreis_liste;

DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis;
DROP INDEX IF EXISTS ungueltige_stimme_stimmentyp;
DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis_stimmentyp;

DELETE
FROM erststimme;
DELETE
FROM zweitstimme;

--Erststimmen
WITH stimmen AS (
    SELECT dk.*, GENERATE_SERIES(1, dk.anzahlstimmen)
    FROM direktkandidatur dk,
         wahlkreis wk
    WHERE dk.wahlkreis = wk.wkid
      AND wk.nummer IN (217, 218, 219, 220, 221)
      AND wk.wahl = 20
)
INSERT
INTO erststimme (kandidatur)
        (SELECT s.direktid FROM stimmen s);

--Index
CREATE INDEX erststimme_kandidatur ON erststimme (kandidatur);

--Zweitstimmen
WITH stimmen AS
         (SELECT zse.*, GENERATE_SERIES(1, zse.anzahlstimmen)
          FROM zweitstimmenergebnis zse,
               wahlkreis wk
          WHERE zse.wahlkreis = wk.wkid
            AND wk.nummer IN (217, 218, 219, 220, 221)
            AND wk.wahl = 20)
INSERT
INTO zweitstimme (liste, wahlkreis)
        (SELECT s.liste, s.wahlkreis FROM stimmen s);

--Indizes
CREATE INDEX zweitstimme_wahlkreis ON zweitstimme (wahlkreis);
CREATE INDEX zweitstimme_liste ON zweitstimme (liste);
CREATE INDEX zweitstimme_wahlkreis_liste ON zweitstimme (wahlkreis, liste);


--Ungültige Stimmen
WITH stimmen AS
         (SELECT use.*, GENERATE_SERIES(1, use.anzahlstimmen)
          FROM ungueltige_stimmen_ergebnis use,
               wahlkreis wk
          WHERE use.wahlkreis = wk.wkid
            AND wk.nummer IN (217, 218, 219, 220, 221)
            AND wk.wahl = 20)
INSERT
INTO ungueltige_stimme (stimmentyp, wahlkreis)
        (SELECT s.stimmentyp, s.wahlkreis FROM stimmen s);

CREATE INDEX ungueltige_stimme_wahlkreis ON ungueltige_stimme (wahlkreis);
CREATE INDEX ungueltige_stimme_stimmentyp ON ungueltige_stimme (stimmentyp);
CREATE INDEX ungueltige_stimme_wahlkreis_stimmentyp ON ungueltige_stimme (stimmentyp, wahlkreis);