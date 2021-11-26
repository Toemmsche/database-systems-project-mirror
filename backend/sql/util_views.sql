DROP MATERIALIZED VIEW IF EXISTS wahlauswahl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS bundesland_bevoelkerung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS qparteien CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzkontigent_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandate_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mindestsitze_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzanspruch_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzanspruch_ohne_ueberhang CASCADE;
DROP MATERIALIZED VIEW IF EXISTS ueberhang_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS qpartei_mit_ueberhang CASCADE;
DROP MATERIALIZED VIEW IF EXISTS divisor_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS divisor_landesliste CASCADE;

CREATE MATERIALIZED VIEW wahlauswahl AS
    VALUES (20);

--German population by state
CREATE MATERIALIZED VIEW bundesland_bevoelkerung(land, bevoelkerung) AS
    /*
SELECT bl.landid AS land, SUM(wk.deutsche) AS bevoelkerung
FROM bundesland bl,
     wahlkreis wk
WHERE wk.land = bl.landid
  AND wk.wahl = (SELECT * FROM wahlauswahl)
GROUP BY bl.landid;*/
    VALUES (1,
             2659792),
            (2,
             1537766),
            (3,
             7207587),
            (4,
             548941),
            (5,
             15415642),
            (6,
             5222158),
            (7,
             3610865),
            (8,
             9313413),
            (9,
             11328866),
            (10,
             865191),
            (11,
             2942960),
            (12,
             2397701),
            (13,
             1532412),
            (14,
             3826905),
            (15,
             2056177),
            (16,
             1996822);


--The winners of each constituency
CREATE MATERIALIZED VIEW direktmandat AS
    SELECT wk.wkid AS wahlkreis, dk.direktid, dk.partei
    FROM direktkandidatur dk,
         wahlkreis wk
    WHERE dk.wahlkreis = wk.wkid
      AND dk.wahl = (SELECT * FROM wahlauswahl)
      AND dk.anzahlstimmen =
          (SELECT MAX(dk1.anzahlstimmen)
           FROM direktkandidatur dk1
           WHERE dk1.wahlkreis = dk.wahlkreis);

--Second votes by party
CREATE MATERIALIZED VIEW zweitstimmen_partei AS
    SELECT p.parteiid AS partei, SUM(zwe.anzahlstimmen) AS anzahlstimmen
    FROM partei p,
         landesliste ll,
         zweitstimmenergebnis zwe
    WHERE p.parteiid = ll.partei
      AND ll.listenid = zwe.liste
      AND ll.wahl = (SELECT * FROM wahlauswahl)
    GROUP BY p.parteiid;

--Second votes by party and state
CREATE MATERIALIZED VIEW zweitstimmen_partei_bundesland AS
    SELECT ll.land, p.parteiid AS partei, SUM(zwe.anzahlstimmen) AS anzahlstimmen
    FROM partei p,
         landesliste ll,
         zweitstimmenergebnis zwe
    WHERE p.parteiid = ll.partei
      AND ll.listenid = zwe.liste
      AND ll.wahl = (SELECT * FROM wahlauswahl)
    GROUP BY ll.land, p.parteiid;

--Second votes by state
CREATE MATERIALIZED VIEW zweitstimmen_bundesland AS
    SELECT land, SUM(anzahlstimmen) AS anzahlstimmen
    FROM zweitstimmen_partei_bundesland
    GROUP BY land;

--All parties that are qualified to receive seats based on the second vote
CREATE MATERIALIZED VIEW qpartei AS
    SELECT p.partei
    FROM zweitstimmen_partei p,
         direktkandidatur dk,
         direktmandat dm
         --Achieve 5% at least
    WHERE p.anzahlstimmen >= 0.05 * (SELECT SUM(anzahlstimmen) FROM zweitstimmen_partei)
    UNION
    SELECT p.parteiid
    FROM partei p,
         direktkandidatur dk,
         direktmandat dm
    WHERE dk.direktid = dm.direktid
      AND p.parteiid = dk.partei
    GROUP BY p.parteiid
             --Obtain three direct seats at least
    HAVING COUNT(*) >= 3;
--TODO nationale minderheit

CREATE MATERIALIZED VIEW zweitstimmen_qpartei AS
    SELECT zs.*
    FROM zweitstimmen_partei zs,
         qpartei p
    WHERE zs.partei = p.partei;

--second votes per qualified party per state
CREATE MATERIALIZED VIEW zweitstimmen_qpartei_bundesland AS
    SELECT *
    FROM zweitstimmen_partei_bundesland
    WHERE partei IN (SELECT * FROM qpartei);

--Number of assigned to each state
CREATE MATERIALIZED VIEW sitze_bundesland AS
    WITH RECURSIVE
        gesamtsitze AS
            (SELECT 2 * COUNT(*)
             FROM wahlkreis
             WHERE wahl = (SELECT * FROM wahlauswahl)),
        anzahl_deutsche AS
            (SELECT SUM(b.bevoelkerung) AS anzahl_deutsche
             FROM bundesland_bevoelkerung b),
        sitzverteilung AS
            (SELECT SUM(ROUND(b.bevoelkerung / (
                    (SELECT *
                     FROM anzahl_deutsche)::decimal / (SELECT * FROM gesamtsitze)))) AS sitze,
                    SUM(b.bevoelkerung)::decimal / (SELECT * FROM gesamtsitze)       AS divisor
             FROM bundesland_bevoelkerung b
             UNION ALL
             (SELECT (SELECT SUM(ROUND(b.bevoelkerung / sv.divisor))
                      FROM bundesland_bevoelkerung b) AS sitze,
                     CASE
                         WHEN sitze < (SELECT * FROM gesamtsitze) THEN sv.divisor - 1
                         WHEN sitze > (SELECT * FROM gesamtsitze) THEN sv.divisor + 1
                         ELSE sv.divisor
                         END
              FROM sitzverteilung sv
              WHERE sitze != (SELECT * FROM gesamtsitze))),
        divisor AS
            (SELECT divisor
             FROM sitzverteilung
             WHERE sitze = (SELECT * FROM gesamtsitze))
    SELECT land, ROUND(bevoelkerung::decimal / (SELECT * FROM divisor)) AS sitze, (SELECT * FROM divisor)
    FROM bundesland_bevoelkerung;

SELECT *
FROM sitze_bundesland;

--Minimum number of seats for each party in each state
CREATE MATERIALIZED VIEW sitzkontingent_qpartei_bundesland AS
    WITH RECURSIVE laender_divisor AS
                       (SELECT zsl.land                                                                 AS land,
                               SUM(ROUND(zsl.anzahlstimmen / (zsl.anzahlstimmen::numeric / sbl.sitze))) AS sitze_ld,
                               zsl.anzahlstimmen::numeric / sbl.sitze                                   AS divisor
                        FROM zweitstimmen_qpartei_bundesland zsp,
                             zweitstimmen_bundesland zsl,
                             sitze_bundesland sbl
                        WHERE zsl.land = sbl.land
                        GROUP BY zsl.land,
                                 zsl.anzahlstimmen,
                                 sbl.sitze
                        UNION ALL
                        (SELECT zsl.land,
                                (SELECT SUM(ROUND(zsl.anzahlstimmen / ld.divisor))
                                 FROM zweitstimmen_qpartei_bundesland zsl
                                 WHERE zsl.land = ld.land) AS sitze_ld,
                                CASE
                                    WHEN sitze < sitze_ld THEN ld.divisor + 1
                                    WHEN sitze > sitze_ld THEN ld.divisor - 1
                                    ELSE ld.divisor
                                    END
                         FROM zweitstimmen_bundesland zsl,
                              laender_divisor ld,
                              sitze_bundesland sbl
                         WHERE zsl.land = ld.land
                           AND zsl.land = sbl.land
                           AND sitze != sitze_ld)
                       )
    SELECT zsl.land,
           zsl.partei,
           ROUND(zsl.anzahlstimmen / ld.divisor) AS sitze
    FROM laender_divisor ld,
         zweitstimmen_qpartei_bundesland zsl,
         sitze_bundesland sbl
    WHERE ld.land = zsl.land
      AND zsl.land = sbl.land
      AND sbl.sitze = ld.sitze_ld;



CREATE MATERIALIZED VIEW direktmandate_qpartei_bundesland AS
    SELECT bl.landid AS land, p.partei AS partei, COUNT(dm.direktid) AS sitze
    FROM ((qpartei p CROSS JOIN bundesland bl)
             LEFT OUTER JOIN direktmandat dm ON dm.partei = p.partei
        AND EXISTS(
                                                        SELECT *
                                                        FROM wahlkreis wk
                                                        WHERE dm.wahlkreis = wk.wkid
                                                          AND wk.land = bl.landid)
        )
    GROUP BY bl.landid, p.partei;

CREATE MATERIALIZED VIEW mindestsitze_qpartei_bundesland AS
    SELECT bl.landid AS land,
           p.partei  AS partei,
           GREATEST(
                   (SELECT mds.sitze
                    FROM direktmandate_qpartei_bundesland mds
                    WHERE mds.partei = p.partei
                      AND mds.land = bl.landid)
               , ROUND(
                               ((SELECT mzs.sitze
                                 FROM sitzkontingent_qpartei_bundesland mzs
                                 WHERE mzs.partei = p.partei
                                   AND mzs.land = bl.landid)
                                   +
                                (SELECT mds.sitze
                                 FROM direktmandate_qpartei_bundesland mds
                                 WHERE mds.partei = p.partei
                                   AND mds.land = bl.landid)
                                   )
                               / 2)
               )     AS minsitze
    FROM qpartei p,
         bundesland bl;



CREATE MATERIALIZED VIEW sitzanspruch_qpartei AS
    SELECT p.partei                                AS partei,
           GREATEST((SELECT SUM(ms.minsitze)
                     FROM mindestsitze_qpartei_bundesland ms
                     WHERE ms.partei = p.partei),
                    (SELECT SUM(mzs.sitze)
                     FROM sitzkontingent_qpartei_bundesland mzs
                     WHERE mzs.partei = p.partei)) AS minsitze
    FROM qpartei p;

select * from sitzanspruch_qpartei;

CREATE MATERIALIZED VIEW sitzanspruch_ohne_ueberhang AS
    SELECT p.*
    FROM sitzanspruch_qpartei p
    WHERE p.minsitze = (SELECT SUM(mzs.sitze)
                        FROM sitzkontingent_qpartei_bundesland mzs
                        WHERE mzs.partei = p.partei);

SELECT *
FROM sitzanspruch_qpartei;

CREATE MATERIALIZED VIEW ueberhang_qpartei_bundesland AS
    SELECT mdm.partei,
           (CASE
                WHEN mdm.sitze > sk.sitze THEN mdm.sitze - sk.sitze
                ELSE 0
               END) AS ueberhang
    FROM sitzkontingent_qpartei_bundesland sk,
         direktmandate_qpartei_bundesland mdm
    WHERE sk.partei = mdm.partei
      AND mdm.land = sk.land;

CREATE MATERIALIZED VIEW qpartei_mit_ueberhang AS
    SELECT DISTINCT p.partei
    FROM qpartei p,
         ueberhang_qpartei_bundesland u
    WHERE u.partei = p.partei
      AND u.ueberhang > 0;

CREATE MATERIALIZED VIEW divisor_qpartei AS
    SELECT FLOOR(LEAST((SELECT MIN(zsp.anzahlstimmen / (msp.minsitze * 1.0000 - 0.5))
                        FROM zweitstimmen_qpartei zsp,
                             sitzanspruch_ohne_ueberhang msp
                        WHERE zsp.partei = msp.partei),
                       (SELECT *
                        FROM (
                                 WITH interval(wert) AS (VALUES (0), (1), (2), (3))
                                 SELECT zs.anzahlstimmen / (msp.minsitze * 1.0000 - i.wert) AS div
                                 FROM qpartei_mit_ueberhang p,
                                      zweitstimmen_partei zs,
                                      sitzanspruch_qpartei msp,
                                      interval i
                                 WHERE p.partei = zs.partei
                                   AND p.partei = msp.partei
                             ) AS ueberhangdivisor
                        ORDER BY div ASC
                        OFFSET 3 LIMIT 1
                       )));


SELECT *
FROM divisor_qpartei;

CREATE MATERIALIZED VIEW sitze_qpartei AS
    SELECT zsp.partei, ROUND(zsp.anzahlstimmen / (SELECT * FROM divisor_qpartei)) AS sitze
    FROM zweitstimmen_qpartei zsp;

SELECT *
FROM sitze_qpartei;
