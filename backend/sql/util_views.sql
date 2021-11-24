DROP MATERIALIZED VIEW IF EXISTS wahlauswahl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS blbevoelkerung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zspartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsbl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS btparteien CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsbtparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzebl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS minsitzeparteibl CASCADE;

CREATE MATERIALIZED VIEW wahlauswahl AS
(
VALUES (20));

--German population by state
CREATE MATERIALIZED VIEW blbevoelkerung AS
(
SELECT bl.landid, SUM(wk.deutsche) AS bevoelkerung
FROM bundesland bl,
     wahlkreis wk
WHERE wk.land = bl.landid
  AND wk.wahl = (SELECT * FROM wahlauswahl)
GROUP BY bl.landid
ORDER BY bl.landid
    );

--The winners of each constituency
CREATE MATERIALIZED VIEW direktmandat AS
(
SELECT wk.wkid, dk.direktid, dk.partei
FROM direktkandidatur dk,
     wahlkreis wk
WHERE dk.wahlkreis = wk.wkid
  AND dk.wahl = (SELECT * FROM wahlauswahl)
  AND dk.anzahlstimmen =
      (SELECT MAX(dk1.anzahlstimmen)
       FROM direktkandidatur dk1
       WHERE dk1.wahlkreis = dk.wahlkreis)
    );

--Second votes by party
CREATE MATERIALIZED VIEW zspartei AS
(
SELECT p.parteiid, SUM(zwe.anzahlstimmen) AS anzahlstimmen
FROM partei p,
     landesliste ll,
     zweitstimmenergebnis zwe
WHERE p.parteiid = ll.partei
  AND ll.listenid = zwe.liste
  AND ll.wahl = (SELECT * FROM wahlauswahl)
GROUP BY p.parteiid
    );

--Second votes by party and state
CREATE MATERIALIZED VIEW zsparteibl AS
(
SELECT ll.land, p.parteiid, SUM(zwe.anzahlstimmen) AS anzahlstimmen
FROM partei p,
     landesliste ll,
     zweitstimmenergebnis zwe
WHERE p.parteiid = ll.partei
  AND ll.listenid = zwe.liste
  AND ll.wahl = (SELECT * FROM wahlauswahl)
GROUP BY ll.land, p.parteiid
    );

--Second votes by state
CREATE MATERIALIZED VIEW zsbl AS
(
SELECT land, SUM(anzahlstimmen) AS anzahlstimmen
FROM zsparteibl
GROUP BY land
    );

--All parties that are qualified to receive seats based on the second vote
CREATE MATERIALIZED VIEW btpartei AS
(
SELECT p.parteiid
FROM zspartei p,
     direktkandidatur dk,
     direktmandate dm
--Achieve 5% at least
WHERE p.anzahlstimmen >= 0.05 * (SELECT SUM(anzahlstimmen) FROM zspartei)
UNION
SELECT p.parteiid
FROM partei p,
     direktkandidatur dk,
     direktmandate dm
WHERE dk.direktid = dm.direktid
  AND p.parteiid = dk.partei
GROUP BY p.parteiid
--Obtain three direct seats at least
HAVING COUNT(*) >= 3
--TODO nationale minderheit
    );

--second votes per qualified party per state
CREATE MATERIALIZED VIEW zsbtparteibl AS
(
SELECT *
FROM zsparteibl
WHERE parteiid IN (SELECT * FROM btpartei)
    );

--Number of assigned to each state
CREATE MATERIALIZED VIEW sitzebl AS
(
WITH gesamtsitze AS (
    SELECT 2 * COUNT(*)
    FROM wahlkreis wk
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
),
     range (index) AS (SELECT GENERATE_SERIES(100000, 200000)),
     divisorverfahren AS (
         SELECT r.index
         FROM blbevoelkerung blb,
              range r
         GROUP BY r.index
         HAVING SUM(ROUND(blb.bevoelkerung * 1.00000000 / r.index)) = (SELECT * FROM gesamtsitze)
         ORDER BY r.index
                  --only take one divisor
         LIMIT 1)
SELECT landid, ROUND(bevoelkerung * 1.00000000 / (SELECT * FROM divisorverfahren)) AS sitze
FROM blbevoelkerung
    );

SELECT *
FROM btpartei;

--Minimum number of seats for each party in each state
CREATE MATERIALIZED VIEW minsitzeparteibl AS
(

WITH range(index) AS (SELECT GENERATE_SERIES(1000, 100000)),
     divisorverfahren AS (
         SELECT zs.land, r.index
         FROM zsbtparteibl zs,
              range r,
              sitzebl bl
         WHERE bl.landid = zs.land
         GROUP BY zs.land, r.index, bl.sitze
         HAVING SUM(ROUND(zs.anzahlstimmen * 1.00000000 / r.index)) = bl.sitze
         ORDER BY r.index),
     singledivisor AS (
         SELECT d.land, MIN(d.index) AS divisor
         FROM divisorverfahren d
         GROUP BY d.land
     ),
     minzssitze AS (
         SELECT zs.land,
                zs.parteiid,
                ROUND(zs.anzahlstimmen * 1.00000000 / d.divisor) AS sitze
         FROM zsbtparteibl zs,
              singledivisor d
         WHERE zs.land = d.land
     )
SELECT bl.landid,
       p.parteiid,
       GREATEST(
               CAST((SELECT mzs.sitze
                     FROM minzssitze mzs
                     WHERE mzs.parteiid = p.parteiid
                       AND mzs.land = bl.landid) AS bigint)
           , (SELECT COUNT(*)
              FROM direktmandat dm,
                   wahlkreis wk
              WHERE dm.wkid = wk.wkid
                AND wk.land = bl.landid
                AND dm.partei = p.parteiid)) AS minsitze
FROM btpartei p,
     bundesland bl

    );

select * from minsitzeparteibl;

CREATE VIEW advanceddivisor AS
(
WITH zuteilungsdivisor AS (
    SELECT zs.land,
           zs.anzahlstimmen /
           (SELECT sb.sitze FROM sitzebl sb WHERE sb.landid = zs.land) AS zuteilungsdivisor
    FROM zsbl zs),
     direction AS (
         SELECT zs.land,
                (CASE
                     WHEN SUM(ROUND(zs.anzahlstimmen * 1.00000000 / d.zuteilungsdivisor)) < bl.sitze THEN -1
                     ELSE 1
                    END)
         FROM zsparteibl zs,
              zuteilungsdivisor d,
              sitzebl bl
         WHERE d.land = zs.land
           AND bl.landid = zs.land
         GROUP BY zs.land, d.zuteilungsdivisor, bl.sitze
     ),
     range(index) AS (SELECT GENERATE_SERIES(1, 2000)),
     divisorverfahren AS (
         SELECT zs.land, r.index
         FROM zsbtparteibl zs,
              range r,
              sitzebl bl
         WHERE bl.landid = zs.land
         GROUP BY zs.land, r.index, bl.sitze
         HAVING SUM(ROUND(zs.anzahlstimmen * 1.00000000 / r.index)) = bl.sitze
         ORDER BY r.index)
SELECT d.land, MIN(d.index) AS divisor
FROM divisorverfahren d
GROUP BY d.land
    );

