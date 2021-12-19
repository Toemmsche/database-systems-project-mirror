DROP VIEW IF EXISTS sitzverteilung CASCADE;

CREATE VIEW sitzverteilung(wahl, partei, partei_farbe, sitze) AS
    SELECT se.wahl, p.kuerzel, p.farbe, se.sitze
    FROM sitzverteilung se,
         partei p
    WHERE se.partei = p.parteiid;