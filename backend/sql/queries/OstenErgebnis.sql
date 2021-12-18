DROP VIEW IF EXISTS zweitstimmen_qpartei_osten CASCADE;

CREATE VIEW zweitstimmen_qpartei_osten(wahl, partei, partei_farbe, abs_stimmen) AS
    SELECT ll.wahl,
           p.kuerzel as partei,
           p.farbe AS partei_farbe,
           SUM(ze.anzahlstimmen) AS abs_stimmen
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
       AND bl.osten
       AND q.wahl = ll.wahl
     GROUP BY p.kuerzel,
              p.farbe,
              ll.wahl
    UNION
    SELECT ll.wahl,
           'Sonstige' AS partei,
           'DDDDDD' AS partei_farbe,
           SUM(ze.anzahlstimmen) AS abs_stimmen
     FROM partei p,
          bundesland bl,
          landesliste ll,
          wahlkreis wk,
          zweitstimmenergebnis ze
     WHERE p.parteiid NOT IN (SELECT qp.partei FROM qpartei qp WHERE qp.wahl = ll.wahl)
       AND ll.partei = p.parteiid
       AND ll.land = bl.landid
       AND wk.land = bl.landid
       AND ze.wahlkreis = wk.wkid
       AND ze.liste = ll.listenid
       AND bl.osten
     GROUP BY ll.wahl;