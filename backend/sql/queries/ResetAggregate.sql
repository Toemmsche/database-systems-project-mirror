DROP FUNCTION IF EXISTS reset_stimmen_aggregat CASCADE;

CREATE OR REPLACE FUNCTION reset_stimmen_aggregat(
    wahl_input INTEGER, wk_nummer_input INTEGER
)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE
    wkid_input INTEGER := (
        SELECT wk.wkid
        FROM wahlkreis wk
        WHERE wk.nummer = wk_nummer_input
          AND wk.wahl = wahl_input
    );
BEGIN

    --Erststimmen
    UPDATE direktkandidatur
    SET anzahlstimmen =
            (SELECT COUNT(*)
             FROM erststimme e
             WHERE e.kandidatur = direktid)
    WHERE wahlkreis = wkid_input;

    --Zweitstimmen
    DELETE
    FROM zweitstimmenergebnis
    WHERE wahlkreis = wkid_input;

    INSERT INTO zweitstimmenergebnis (liste, wahlkreis, anzahlstimmen) (
        SELECT zs.liste, zs.wahlkreis, COUNT(*)
        FROM zweitstimme zs
        WHERE wahlkreis = wkid_input
        GROUP BY zs.liste, zs.wahlkreis
    );
END
$$