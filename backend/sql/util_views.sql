DROP MATERIALIZED VIEW IF EXISTS wahlauswahl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS blbevoelkerung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zspartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsbl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS btparteien CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsbtpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zsbtparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzebl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzkontigentparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mindmsitzeparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS minsitzeparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzanspruchpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS anspruchohneueberhang CASCADE;
DROP MATERIALIZED VIEW IF EXISTS ueberhangparteibl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS ueberhangpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS divisorobergrenze CASCADE;
DROP MATERIALIZED VIEW IF EXISTS finalesitze CASCADE;
DROP MATERIALIZED VIEW IF EXISTS llsitzeparteibl CASCADE;

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
     direktmandat dm
--Achieve 5% at least
WHERE p.anzahlstimmen >= 0.05 * (SELECT SUM(anzahlstimmen) FROM zspartei)
UNION
SELECT p.parteiid
FROM partei p,
     direktkandidatur dk,
     direktmandat dm
WHERE dk.direktid = dm.direktid
  AND p.parteiid = dk.partei
GROUP BY p.parteiid
--Obtain three direct seats at least
HAVING COUNT(*) >= 3
--TODO nationale minderheit
    );

CREATE MATERIALIZED VIEW zsbtpartei AS
(
SELECT zs.*
FROM zspartei zs,
     btpartei p
WHERE zs.parteiid = p.parteiid

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
CREATE MATERIALIZED VIEW sitzkontingentparteibl AS
(
WITH range(index) AS (SELECT GENERATE_SERIES(60000, 90000)),
     divisorverfahren AS (
         SELECT bl.landid AS land,
                (
                    SELECT r.index
                    FROM range r,
                         zsbtparteibl zs,
                         sitzebl sbl
                    WHERE sbl.landid = zs.land
                      AND bl.landid = zs.land
                    GROUP BY zs.land, r.index, sbl.sitze
                    HAVING SUM(ROUND(zs.anzahlstimmen * 1.00000000 / r.index)) = sbl.sitze
                    LIMIT 1
                )         AS divisor
         FROM bundesland bl
     )
SELECT zs.land,
       zs.parteiid,
       ROUND(zs.anzahlstimmen * 1.00000000 / d.divisor) AS sitze
FROM zsbtparteibl zs,
     divisorverfahren d
WHERE zs.land = d.land
    );


CREATE MATERIALIZED VIEW mindmsitzeparteibl AS
(
SELECT bl.landid AS land, p.parteiid AS partei, COUNT(dm.direktid) AS sitze
FROM ((btpartei p CROSS JOIN bundesland bl)
         LEFT OUTER JOIN direktmandat dm ON dm.partei = p.parteiid
    AND EXISTS(
                                                    SELECT *
                                                    FROM wahlkreis wk
                                                    WHERE dm.wkid = wk.wkid
                                                      AND wk.land = bl.landid)
    )
GROUP BY bl.landid, p.parteiid);

CREATE MATERIALIZED VIEW minsitzeparteibl AS
(
SELECT bl.landid  AS land,
       p.parteiid AS partei,
       GREATEST(
               (SELECT mds.sitze
                FROM mindmsitzeparteibl mds
                WHERE mds.partei = p.parteiid
                  AND mds.land = bl.landid)
           , ROUND(((SELECT mzs.sitze
                     FROM sitzkontingentparteibl mzs
                     WHERE mzs.parteiid = p.parteiid
                       AND mzs.land = bl.landid)
           +
                    (SELECT mds.sitze
                     FROM mindmsitzeparteibl mds
                     WHERE mds.partei = p.parteiid
                       AND mds.land = bl.landid)
                       )
           / 2))  AS minsitze
FROM btpartei p,
     bundesland bl );

CREATE MATERIALIZED VIEW sitzanspruchpartei AS
(
SELECT p.parteiid                                  AS partei,
       GREATEST((
                    SELECT SUM(ms.minsitze)
                    FROM minsitzeparteibl ms
                    WHERE ms.partei = p.parteiid),
                (SELECT SUM(mzs.sitze)
                 FROM sitzkontingentparteibl mzs
                 WHERE mzs.parteiid = p.parteiid)) AS minsitze
FROM btpartei p
    );

CREATE MATERIALIZED VIEW anspruchohneueberhang AS
(
SELECT p.*
FROM sitzanspruchpartei p
WHERE p.minsitze = (SELECT SUM(mzs.sitze)
                    FROM sitzkontingentparteibl mzs
                    WHERE mzs.parteiid = p.partei)
    );

SELECT *
FROM sitzanspruchpartei;

CREATE MATERIALIZED VIEW ueberhangparteibl AS
(
SELECT mdm.partei,
       (CASE
            WHEN mdm.sitze > sk.sitze THEN mdm.sitze - sk.sitze
            ELSE 0
           END) AS ueberhang
FROM sitzkontingentparteibl sk,
     mindmsitzeparteibl mdm
WHERE sk.parteiid = mdm.partei
  AND mdm.land = sk.land
    );

CREATE MATERIALIZED VIEW ueberhangpartei AS
(
SELECT DISTINCT p.parteiid
FROM btpartei p,
     ueberhangparteibl u
WHERE u.partei = p.parteiid
  AND u.ueberhang > 0
    );

SELECT *
FROM (
         SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 0.5) AS div
         FROM ueberhangpartei p,
              zspartei zs,
              sitzanspruchpartei msp
         WHERE p.parteiid = zs.parteiid
           AND p.parteiid = msp.partei
         UNION
         SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 1.5) AS div
         FROM ueberhangpartei p,
              zspartei zs,
              sitzanspruchpartei msp
         WHERE p.parteiid = zs.parteiid
           AND p.parteiid = msp.partei
         UNION
         SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 2.5) AS div
         FROM ueberhangpartei p,
              zspartei zs,
              sitzanspruchpartei msp
         WHERE p.parteiid = zs.parteiid
           AND p.parteiid = msp.partei
         UNION
         SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 3.5) AS div
         FROM ueberhangpartei p,
              zspartei zs,
              sitzanspruchpartei msp
         WHERE p.parteiid = zs.parteiid
           AND p.parteiid = msp.partei
     ) AS ueberhangdivisor
ORDER BY div ASC
OFFSET 3 LIMIT 1;


CREATE MATERIALIZED VIEW endgueltigerdivisor AS
(
SELECT FLOOR(LEAST((SELECT MIN(zsp.anzahlstimmen / (msp.minsitze * 1.0000 - 0.5))
                    FROM zsbtpartei zsp,
                         anspruchohneueberhang msp
                    WHERE zsp.parteiid = msp.partei),
                   (SELECT *
                    FROM (
                             SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 0.5) AS div
                             FROM ueberhangpartei p,
                                  zspartei zs,
                                  sitzanspruchpartei msp
                             WHERE p.parteiid = zs.parteiid
                               AND p.parteiid = msp.partei
                             UNION
                             SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 1.5) AS div
                             FROM ueberhangpartei p,
                                  zspartei zs,
                                  sitzanspruchpartei msp
                             WHERE p.parteiid = zs.parteiid
                               AND p.parteiid = msp.partei
                             UNION
                             SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 2.5) AS div
                             FROM ueberhangpartei p,
                                  zspartei zs,
                                  sitzanspruchpartei msp
                             WHERE p.parteiid = zs.parteiid
                               AND p.parteiid = msp.partei
                             UNION
                             SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - 3.5) AS div
                             FROM ueberhangpartei p,
                                  zspartei zs,
                                  sitzanspruchpartei msp
                             WHERE p.parteiid = zs.parteiid
                               AND p.parteiid = msp.partei
                         ) AS ueberhangdivisor
                    ORDER BY div ASC
                    OFFSET 3 LIMIT 1
                   ))));



CREATE MATERIALIZED VIEW finalesitze AS
(
SELECT zsp.parteiid, ROUND(zsp.anzahlstimmen / (SELECT * FROM endgueltigerdivisor)) AS sitze
FROM zsbtpartei zsp
    );

SELECT *
FROM finalesitze;

--TODO ÜBERHANGE
CREATE MATERIALIZED VIEW llsitzeparteibl AS
(
WITH range(index) AS (SELECT GENERATE_SERIES(1000, 100000))
SELECT p.parteiid AS partei,
       (
           SELECT r.index
           FROM range r,
                finalesitze fs,
                zsbtparteibl zs
           WHERE fs.parteiid = p.parteiid
             AND zs.parteiid = p.parteiid
           GROUP BY fs.parteiid, r.index, fs.sitze
           HAVING SUM(GREATEST(ROUND(zs.anzahlstimmen * 1.00000000 / r.index),
                               (SELECT msp.minsitze
                                FROM minsitzeparteibl msp
                                WHERE msp.partei = zs.parteiid
                                  AND msp.land = zs.land)
               )) = fs.sitze
           LIMIT 1
       )          AS divisor
FROM btpartei p
    );



SELECT *
FROM llsitzeparteibl;

/*

 */