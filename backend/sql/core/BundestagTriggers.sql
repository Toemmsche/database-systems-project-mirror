DROP FUNCTION IF EXISTS refresh_mandat CASCADE;
DROP TRIGGER IF EXISTS mandat_erststimmen_refresh ON direktkandidatur CASCADE;
DROP TRIGGER IF EXISTS mandat_zweitimmen_refresh ON direktkandidatur CASCADE;

--MANDATE
CREATE FUNCTION refresh_mandat()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW mandat;
    RETURN NULL;
END;
$$;

CREATE TRIGGER mandat_erststimmen_refresh
    AFTER UPDATE OR INSERT
    ON direktkandidatur
EXECUTE PROCEDURE refresh_mandat();

CREATE TRIGGER mandat_zweitstimmen_refresh
    AFTER UPDATE OR INSERT
    ON zweitstimmenergebnis
EXECUTE PROCEDURE refresh_mandat();