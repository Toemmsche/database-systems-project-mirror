-Aggregate zweitstimmen
DELETE
FROM zweitstimmenergebnis;

INSERT INTO zweitstimmenergebnis(liste, wahlkreis, anzahlstimmen)
    (SELECT zs.liste, zs.wahlkreis, COUNT(*)
     FROM zweitstimme zs
     GROUP BY zs.liste, zs.wahlkreis);

--Aggregate erststimmen
UPDATE direktkandidatur dk
SET anzahlstimmen = (
    SELECT COUNT(*)
    FROM erststimme es
    WHERE es.kandidatur = dk.direktid
);


