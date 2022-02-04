DROP FUNCTION IF EXISTS update_erststimmen_aggregate CASCADE;
DROP TRIGGER IF EXISTS erststimmen_aggregat_refresh ON erststimme CASCADE;
DROP FUNCTION IF EXISTS update_zweitstimmen_aggregate CASCADE;
DROP TRIGGER IF EXISTS zweitstimmen_aggregat_refresh ON zweitstimme CASCADE;
DROP FUNCTION IF EXISTS update_ungueltige_stimmen_aggregate CASCADE;
DROP TRIGGER IF EXISTS ungueltige_stimmen_aggregat_refresh ON ungueltige_stimme CASCADE;

--ERSTSTIMMENAGGREGAT
CREATE FUNCTION update_erststimmen_aggregate()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE direktkandidatur
    SET anzahlstimmen = anzahlstimmen + 1
    WHERE direktid = new.kandidatur;
    RETURN NULL;
END
$$;

CREATE TRIGGER erststimmen_aggregat_refresh
    AFTER INSERT
    ON erststimme
    FOR EACH ROW
EXECUTE PROCEDURE update_erststimmen_aggregate();


--ZWEITSTIMMENAGGREGAT
CREATE FUNCTION update_zweitstimmen_aggregate()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    --insert new zweitstimmenergebnis if missing
    IF NOT EXISTS(SELECT * FROM zweitstimmenergebnis WHERE liste = new.liste AND wahlkreis = new.wahlkreis) THEN
        INSERT INTO zweitstimmenergebnis VALUES (new.liste, new.wahlkreis, 0);
    END IF;

    UPDATE zweitstimmenergebnis
    SET anzahlstimmen = anzahlstimmen + 1
    WHERE liste = new.liste
      AND wahlkreis = new.wahlkreis;
    RETURN NULL;
END
$$;

CREATE TRIGGER zweitstimmen_aggregat_refresh
    AFTER INSERT
    ON zweitstimme
    FOR EACH ROW
EXECUTE PROCEDURE update_zweitstimmen_aggregate();


--Ungültige Stimmen Aggregat
CREATE FUNCTION update_ungueltige_stimmen_aggregate()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE ungueltige_stimmen_ergebnis
    SET anzahlstimmen = anzahlstimmen + 1
    WHERE stimmentyp = new.stimmentyp
      AND wahlkreis = new.wahlkreis;
    RETURN NULL;
END
$$;

CREATE TRIGGER ungueltige_stimmen_aggregat_refresh
    AFTER INSERT
    ON ungueltige_stimme
    FOR EACH ROW
EXECUTE PROCEDURE update_ungueltige_stimmen_aggregate();
