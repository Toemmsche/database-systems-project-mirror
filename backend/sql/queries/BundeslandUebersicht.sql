DROP VIEW IF EXISTS stimmen_qpartei_bundesland CASCADE;

CREATE VIEW stimmen_qpartei_bundesland (wahl, bl_kuerzel, partei, partei_farbe, abs_stimmen, rel_stimmen) AS
    WITH qpartei(wahl, partei) AS
             (SELECT DISTINCT m.wahl, m.partei
              FROM mandat m),
         nicht_qpartei(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
                  EXCEPT
              SELECT *
              FROM qpartei),
         zweitstimmen_partei_wahlkreis(wahl, wahlkreis, land, partei, abs_stimmen) AS
             (SELECT wk.wahl,
                     wk.wkid,
                     wk.land,
                     ll.partei,
                     ze.anzahlstimmen
              FROM wahlkreis wk,
                   landesliste ll,
                   zweitstimmenergebnis ze
              WHERE wk.wkid = ze.wahlkreis
                AND ze.liste = ll.listenid),
         zweitstimmen_partei_land(wahl, land, partei, abs_stimmen) AS
             (SELECT zpw.wahl, zpw.land, zpw.partei, SUM(zpw.abs_stimmen)
              FROM zweitstimmen_partei_wahlkreis zpw
              GROUP BY zpw.wahl, zpw.land, zpw.partei),
         zweitstimmen_land(wahl, land, abs_stimmen) AS
             (SELECT zpl.wahl, zpl.land, SUM(zpl.abs_stimmen)
              FROM zweitstimmen_partei_land zpl
              GROUP BY zpl.wahl, zpl.land)
    SELECT zpl.wahl,
           bl.kuerzel,
           p.kuerzel,
           p.farbe,
           zpl.abs_stimmen,
           zpl.abs_stimmen::DECIMAL / zl.abs_stimmen AS rel_stimmen
    FROM zweitstimmen_partei_land zpl,
         zweitstimmen_land zl,
         partei p,
         qpartei qp,
         bundesland bl
    WHERE zpl.wahl = qp.wahl
      AND zpl.wahl = zl.wahl
      AND zpl.partei = p.parteiid
      AND zpl.partei = qp.partei
      AND zpl.land = bl.landid
      AND zpl.land = zl.land
    UNION
    SELECT zpl.wahl,
           bl.kuerzel,
           'Sonstige',
           'DDDDDD',
           SUM(zpl.abs_stimmen)                           AS abs_stimmen,
           SUM(zpl.abs_stimmen)::DECIMAL / zl.abs_stimmen AS rel_stimmen
    FROM zweitstimmen_partei_land zpl,
         zweitstimmen_land zl,
         partei p,
         nicht_qpartei nqp,
         bundesland bl
    WHERE zpl.wahl = nqp.wahl
      AND zpl.wahl = zl.wahl
      AND zpl.partei = p.parteiid
      AND zpl.partei = nqp.partei
      AND zpl.land = bl.landid
      AND zpl.land = zl.land
    GROUP BY zpl.wahl, bl.kuerzel, zl.abs_stimmen;

