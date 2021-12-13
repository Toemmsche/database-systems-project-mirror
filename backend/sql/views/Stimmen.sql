DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei_wahlkreis CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei CASCADE;

--Zweitstimmen aggregiert nach Wahl, Walhkreis, und Partei
CREATE MATERIALIZED VIEW zweitstimmen_partei_wahlkreis(wahl, wahlkreis, partei, anzahlstimmen) AS
    SELECT wk.wahl, wk.wkid, p.parteiid, SUM(ze.anzahlstimmen)
    FROM wahlkreis wk,
         landesliste ll,
         partei p,
         zweitstimmenergebnis ze
    WHERE wk.wkid = ze.wahlkreis
      AND ze.liste = ll.listenid
      AND ll.partei = p.parteiid
      AND ll.land = wk.land --sollte überflüssig sein
    GROUP BY wk.wahl, wk.wkid, p.parteiid;

--Zweitstimmen aggregiert nach Wahl, Bundesland, und Partei
CREATE MATERIALIZED VIEW zweitstimmen_partei_bundesland(wahl, land, partei, anzahlstimmen) AS
    SELECT zpw.wahl, wk.land, zpw.partei, SUM(zpw.anzahlstimmen)
    FROM wahlkreis wk,
         zweitstimmen_partei_wahlkreis zpw
    WHERE wk.wkid = zpw.wahlkreis
    GROUP BY zpw.wahl, wk.land, zpw.partei;

--Zweitstimmen aggregiert nach Wahl und Partei
CREATE MATERIALIZED VIEW zweitstimmen_partei(wahl, partei, anzahlstimmen) AS
    SELECT zpb.wahl, zpb.partei, SUM(zpb.anzahlstimmen)
    FROM zweitstimmen_partei_bundesland zpb
    GROUP BY zpb.wahl, zpb.partei;

