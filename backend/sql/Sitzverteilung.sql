DROP MATERIALIZED VIEW IF EXISTS sitzverteilung CASCADE;

CREATE MATERIALIZED VIEW sitzverteilung AS
    SELECT m.kuerzel, COUNT(*) as sitze
    FROM mandate m
    GROUP BY m.kuerzel;