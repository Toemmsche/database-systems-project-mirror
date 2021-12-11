DROP MATERIALIZED VIEW IF EXISTS sitzverteilung CASCADE;

CREATE MATERIALIZED VIEW sitzverteilung AS
    SELECT p.kuerzel as partei, p.farbe as partei_farbe, COUNT(*) AS sitze
    FROM mandate m,
         partei p
    WHERE m.partei = p.kuerzel
    GROUP BY p.kuerzel, p.farbe;