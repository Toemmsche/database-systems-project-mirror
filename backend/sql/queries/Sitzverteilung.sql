DROP VIEW IF EXISTS sitzverteilung CASCADE;

CREATE VIEW sitzverteilung(wahl, partei, partei_farbe, sitze) AS
    SELECT m.wahl, p.kuerzel, p.farbe, COUNT(*)
    FROM mandat m,
         partei p
    WHERE m.partei = p.parteiid
    GROUP BY m.wahl, p.kuerzel, p.farbe;

