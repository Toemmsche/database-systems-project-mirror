DROP FUNCTION IF EXISTS reset_stimmen_aggregat CASCADE;

CREATE OR REPLACE FUNCTION reset_stimmen_aggregat(
    wahl_input INTEGER, wk_nummer_input INTEGER
)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    wkid_input     INTEGER := (
        SELECT wk.wkid
        FROM wahlkreis wk
        WHERE wk.nummer = wk_nummer_input
          AND wk.wahl = wahl_input
    );
    reset_possible BOOLEAN := (
                (SELECT COUNT(*)
                 FROM erststimme es,
                      direktkandidatur dk
                 WHERE dk.wahlkreis = wkid_input
                   AND es.kandidatur = dk.direktid) =
                (SELECT SUM(dk.anzahlstimmen)
                 FROM direktkandidatur dk
                 WHERE dk.wahlkreis = wkid_input
                )
            AND
                (SELECT COUNT(*)
                 FROM zweitstimme zs
                 WHERE zs.wahlkreis = wkid_input) =
                (SELECT SUM(ze.anzahlstimmen)
                 FROM zweitstimmenergebnis ze
                 WHERE ze.wahlkreis = wkid_input
                )
            AND (SELECT COUNT(*)
                 FROM ungueltige_stimme us
                 WHERE us.wahlkreis = wkid_input) =
                (SELECT SUM(use.anzahlstimmen)
                 FROM ungueltige_stimmen_ergebnis use
                 WHERE use.wahlkreis = wkid_input
                )
        );
BEGIN
    IF reset_possible THEN
        --Erststimmen
        UPDATE
            direktkandidatur
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
            SELECT zs.liste,
                   zs.wahlkreis,
                   COUNT(*)
            FROM zweitstimme zs
            WHERE zs.wahlkreis = wkid_input
            GROUP BY zs.liste, zs.wahlkreis
        );

        --ungueltige stimmen
        DELETE
        FROM ungueltige_stimmen_ergebnis
        WHERE wahlkreis = wkid_input;

        INSERT INTO ungueltige_stimmen_ergebnis (stimmentyp, wahlkreis, anzahlstimmen) (
            SELECT us.stimmentyp,
                   us.wahlkreis,
                   COUNT(*)
            FROM ungueltige_stimme us
            WHERE us.wahlkreis = wkid_input
            GROUP BY us.stimmentyp, us.wahlkreis
        );
    END IF;
    RETURN reset_possible;
END
$$