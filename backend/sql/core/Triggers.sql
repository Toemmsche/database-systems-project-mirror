DROP FUNCTION IF EXISTS update_erststimmen_aggregate CASCADE;
DROP TRIGGER IF EXISTS erststimmen_aggregat_refresh ON erststimme CASCADE;
DROP FUNCTION IF EXISTS update_zweitstimmen_aggregate CASCADE;
DROP TRIGGER IF EXISTS zweitstimmen_aggregat_refresh ON erststimme CASCADE;

--ERSTSTIMMENAGGREGAT
CREATE FUNCTION update_erststimmen_aggregate()
    RETURNS trigger
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
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE zweitstimmenergebnis
    SET anzahlstimmen = anzahlstimmen + 1
    WHERE liste = new.liste;
    RETURN NULL;
END
$$;

CREATE TRIGGER zweitstimmen_aggregat_refresh
    AFTER INSERT
    ON zweitstimme
    FOR EACH ROW
EXECUTE PROCEDURE update_zweitstimmen_aggregate();
