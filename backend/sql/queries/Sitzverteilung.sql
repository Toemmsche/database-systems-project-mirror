DROP MATERIALIZED VIEW IF EXISTS sitzverteilung CASCADE;

CREATE MATERIALIZED VIEW sitzverteilung AS
    SELECT p.kuerzel, p.farbe, COUNT(*) AS sitze
    FROM mandate m,
         partei p
    WHERE m.partei = p.kuerzel
    GROUP BY p.kuerzel, p.farbe;