DROP VIEW IF EXISTS sitzverteilung CASCADE;

CREATE VIEW sitzverteilung(wahl, partei, partei_farbe, sitze, sitze_rel, sitze_vor, sitze_vor_rel) AS
    WITH sitzverteilung_ohne_vorperiode(wahl, partei, partei_farbe, sitze, sitze_gesamt) AS (
        SELECT m.wahl,
               p.kuerzel,
               p.farbe,
               COUNT(*),
               (SELECT COUNT(*) FROM mandat mg WHERE mg.wahl = m.wahl)
        FROM mandat m,
             partei p
        WHERE m.partei = p.parteiid
        GROUP BY m.wahl, p.kuerzel, p.farbe)

    SELECT akt.wahl, akt.partei, akt.partei_farbe, akt.sitze, akt.sitze::DECIMAL / akt.sitze_gesamt, vor.sitze, vor.sitze::DECIMAL / vor.sitze_gesamt
    FROM sitzverteilung_ohne_vorperiode akt FULL OUTER JOIN sitzverteilung_ohne_vorperiode vor ON akt.partei = vor.partei AND akt.wahl = vor.wahl + 1

