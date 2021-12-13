DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_qpartei_osten CASCADE;


CREATE MATERIALIZED VIEW zweitstimmen_qpartei_osten AS
    (SELECT p.kuerzel as partei, p.farbe AS partei_farbe, SUM(ze.anzahlstimmen) AS abs_stimmen
     FROM qpartei q,
          partei p,
          landesliste ll,
          bundesland bl,
          wahlkreis wk,
          zweitstimmenergebnis ze
     WHERE q.partei = p.parteiid
       AND ll.partei = p.parteiid
       AND ll.land = bl.landid
       AND wk.land = bl.landid
       AND ze.wahlkreis = wk.wkid
       AND ze.liste = ll.listenid
       AND bl.osten = B'1'
     GROUP BY p.kuerzel, p.farbe)
    UNION
    (SELECT 'Sonstige' AS partei, 'DDDDDD' AS partei_farbe, SUM(ze.anzahlstimmen) AS abs_stimmen
     FROM partei p,
          bundesland bl,
          landesliste ll,
          wahlkreis wk,
          zweitstimmenergebnis ze
     WHERE p.parteiid NOT IN (SELECT * FROM qpartei)
       AND ll.partei = p.parteiid
       AND ll.land = bl.landid
       AND wk.land = bl.landid
       AND ze.wahlkreis = wk.wkid
       AND ze.liste = ll.listenid
       AND bl.osten = B'1');

SELECT *
FROM zweitstimmen_qpartei_osten;