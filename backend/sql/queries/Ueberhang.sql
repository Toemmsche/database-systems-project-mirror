DROP VIEW IF EXISTS ueberhang_qpartei_bundesland CASCADE;

CREATE VIEW ueberhang_qpartei_bundesland(wahl, land, partei, partei_farbe, ueberhang) AS
    SELECT DISTINCT m.wahl, bl.name, p.kuerzel, p.farbe, m.ueberhang_land
    FROM mandat m,
         partei p,
         bundesland bl
    WHERE m.partei = p.parteiid
      AND m.land = bl.landid
      AND m.ueberhang_land > 0;
