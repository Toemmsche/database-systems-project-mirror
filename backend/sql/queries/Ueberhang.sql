DROP MATERIALIZED VIEW IF EXISTS ueberhang_qpartei_bundesland CASCADE;

CREATE MATERIALIZED VIEW ueberhang_qpartei_bundesland AS
    SELECT bl.name AS bundesland, p.kuerzel AS partei, p.farbe as partei_farbe, ms.ueberhang
    FROM mindestsitze_qpartei_bundesland ms,
         partei p,
         bundesland bl
    WHERE ms.partei = p.parteiid
      AND bl.landid = ms.land;

