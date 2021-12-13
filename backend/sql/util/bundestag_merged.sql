DROP MATERIALIZED VIEW IF EXISTS wahlauswahl CASCADE;
DROP MATERIALIZED VIEW IF EXISTS divisor_kandidat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS bundesland_bevoelkerung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_partei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS zweitstimmen_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzkontigent_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzkontigent_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS direktmandate_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mindestsitze_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitzanspruch_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS ueberhang_qpartei_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_nach_erhoehung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS verbleibende_sitze_landesliste CASCADE;
DROP MATERIALIZED VIEW IF EXISTS landeslisten_ohne_direktmandate CASCADE;
DROP MATERIALIZED VIEW IF EXISTS listenmandate CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mandate CASCADE;

CREATE MATERIALIZED VIEW wahlauswahl AS
    VALUES (20);

--German population by state
CREATE MATERIALIZED VIEW bundesland_bevoelkerung(land, bevoelkerung) AS
    /*
SELECT bl.landid AS land, SUM(wk.bundesland_bevoelkerung) AS bevoelkerung
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
    SELECT wk.wkid AS wahlkreis,
           wk.land,
           dk.direktid,
           dk.partei,
           dk.kandidat,
           dk.anzahlstimmen
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

CREATE MATERIALIZED VIEW divisor_kandidat(divisor) AS
    VALUES (0),
           (1);

--Number of assigned to each state
CREATE MATERIALIZED VIEW sitze_bundesland AS
    WITH RECURSIVE
        gesamtsitze AS
            (SELECT 2 * COUNT(*)
             FROM wahlkreis
             WHERE wahl = (SELECT * FROM wahlauswahl)),
        anzahl_bundesland_bevoelkerung AS
            (SELECT SUM(b.bevoelkerung) AS anzahl_bundesland_bevoelkerung
             FROM bundesland_bevoelkerung b),
        sitzverteilung AS
            (SELECT SUM(ROUND(b.bevoelkerung / (
                    (SELECT *
                     FROM anzahl_bundesland_bevoelkerung)::decimal / (SELECT * FROM gesamtsitze)))) AS sitze,
                    SUM(b.bevoelkerung)::decimal / (SELECT * FROM gesamtsitze)                      AS divisor,
                    SUM(b.bevoelkerung)::decimal / (SELECT * FROM gesamtsitze)                      AS next_divisor
             FROM bundesland_bevoelkerung b
             UNION ALL
             (SELECT (SELECT SUM(ROUND(b.bevoelkerung / sv.divisor))
                      FROM bundesland_bevoelkerung b) AS sitze,
                     sv.next_divisor,
                     CASE
                         WHEN sitze < (SELECT * FROM gesamtsitze) THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT b.bevoelkerung /
                                           (ROUND(b.bevoelkerung / sv.next_divisor) + 0.5 + dk.divisor) AS divisor
                                    FROM bundesland_bevoelkerung b,
                                         divisor_kandidat dk
                                    ORDER BY divisor DESC
                                    LIMIT 2) AS d)
                         WHEN sitze > (SELECT * FROM gesamtsitze) THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT b.bevoelkerung /
                                           (ROUND(b.bevoelkerung / sv.next_divisor) - 0.5 - dk.divisor) AS divisor
                                    FROM bundesland_bevoelkerung b,
                                         divisor_kandidat dk
                                    ORDER BY divisor
                                    LIMIT 2) AS d)
                         ELSE sv.next_divisor
                         END
              FROM sitzverteilung sv
              WHERE sitze != (SELECT * FROM gesamtsitze))),
        divisor AS
            (SELECT divisor
             FROM sitzverteilung
             WHERE sitze = (SELECT * FROM gesamtsitze))
    SELECT land, ROUND(bevoelkerung::decimal / (SELECT * FROM divisor)) AS sitze, (SELECT * FROM divisor)
    FROM bundesland_bevoelkerung;

--Minimum number of seats for each party in each state
CREATE MATERIALIZED VIEW sitzkontingent_qpartei_bundesland AS
    WITH RECURSIVE laender_divisor AS
                       (SELECT zsl.land                                                                 AS land,
                               SUM(ROUND(zsl.anzahlstimmen / (zsl.anzahlstimmen::numeric / sbl.sitze))) AS sitze_ld,
                               zsl.anzahlstimmen::numeric / sbl.sitze                                   AS divisor,
                               zsl.anzahlstimmen::numeric / sbl.sitze                                   AS next_divisor
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
                                ld.next_divisor,
                                CASE
                                    WHEN sitze < ld.sitze_ld THEN
                                        (SELECT AVG(d.divisor)
                                         FROM (SELECT zs.anzahlstimmen /
                                                      (ROUND(zs.anzahlstimmen / ld.next_divisor) - 0.5 - dk.divisor) AS divisor
                                               FROM divisor_kandidat dk,
                                                    zweitstimmen_qpartei_bundesland zs
                                               WHERE zs.land = zsl.land
                                                 AND ROUND(zs.anzahlstimmen / ld.next_divisor) > dk.divisor
                                               ORDER BY divisor
                                               LIMIT 2) AS d)
                                    WHEN sitze > ld.sitze_ld THEN
                                        (SELECT AVG(d.divisor)
                                         FROM (SELECT zs.anzahlstimmen /
                                                      (ROUND(zs.anzahlstimmen / ld.next_divisor) + 0.5 + dk.divisor) AS divisor
                                               FROM divisor_kandidat dk,
                                                    zweitstimmen_qpartei_bundesland zs
                                               WHERE zs.land = zsl.land
                                               ORDER BY divisor DESC
                                               LIMIT 2) AS d)
                                    ELSE ld.next_divisor
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
           ROUND(zsl.anzahlstimmen / ld.divisor) AS sitzkontingent
    FROM laender_divisor ld,
         zweitstimmen_qpartei_bundesland zsl,
         sitze_bundesland sbl
    WHERE ld.land = zsl.land
      AND zsl.land = sbl.land
      AND sbl.sitze = ld.sitze_ld;

CREATE MATERIALIZED VIEW sitzkontingent_qpartei AS
    SELECT mzs.partei, SUM(sitzkontingent) AS sitzkontingent
    FROM sitzkontingent_qpartei_bundesland mzs
    GROUP BY mzs.partei;


CREATE MATERIALIZED VIEW direktmandate_qpartei_bundesland AS
    SELECT bl.landid AS land, p.partei AS partei, COUNT(dm.direktid) AS direktmandate
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
    SELECT sk.land,
           sk.partei,
           sk.sitzkontingent,
           GREATEST(mdm.direktmandate, ROUND((sk.sitzkontingent + mdm.direktmandate) / 2)) AS mindestsitze,
           (CASE
                WHEN mdm.direktmandate > sk.sitzkontingent THEN mdm.direktmandate - sk.sitzkontingent
                ELSE 0
               END)                                                                        AS ueberhang

    FROM sitzkontingent_qpartei_bundesland sk,
         direktmandate_qpartei_bundesland mdm
    WHERE sk.partei = mdm.partei
      AND sk.land = mdm.land;

CREATE MATERIALIZED VIEW sitzanspruch_qpartei AS
    SELECT mp.partei,
           SUM(mp.sitzkontingent)                                 AS sitzkontingent,
           GREATEST(SUM(mp.sitzkontingent), SUM(mp.mindestsitze)) AS mindestsitzanspruch,
           SUM(mp.ueberhang)                                      AS drohender_ueberhang,
           zs.anzahlstimmen
    FROM mindestsitze_qpartei_bundesland mp,
         zweitstimmen_qpartei zs
    WHERE mp.partei = zs.partei
    GROUP BY mp.partei, zs.anzahlstimmen;

CREATE MATERIALIZED VIEW sitze_nach_erhoehung AS
    WITH divisor_obergrenze AS
             (SELECT LEAST(
                             (SELECT sp.anzahlstimmen / (sp.sitzkontingent::numeric - 0.5) AS divisor
                              FROM sitzanspruch_qpartei sp
                              ORDER BY divisor
                              LIMIT 1),
                             (WITH ueberhang(ueberhang) AS (VALUES (0.0), (1.0), (2.0), (3.0))
                              SELECT sp.anzahlstimmen / (sp.mindestsitzanspruch::numeric - u.ueberhang - 0.5) AS divisor
                              FROM sitzanspruch_qpartei sp,
                                   ueberhang u
                              WHERE sp.drohender_ueberhang > u.ueberhang
                              ORDER BY divisor ASC
                              OFFSET 3 LIMIT 1)
                         ) AS obergrenze),
         divisor_untergrenze AS
             (SELECT zs.anzahlstimmen / (ROUND(zs.anzahlstimmen / d.obergrenze) + 0.5) AS untergrenze
              FROM zweitstimmen_qpartei zs,
                   divisor_obergrenze d
              ORDER BY untergrenze DESC
              LIMIT 1),
         engueltiger_divisor AS
             (SELECT (u.untergrenze + o.obergrenze) / 2 AS divisor
              FROM divisor_untergrenze u,
                   divisor_obergrenze o)
    SELECT sp.partei,
           GREATEST(ROUND(sp.anzahlstimmen / (SELECT * FROM engueltiger_divisor)), sp.mindestsitzanspruch) AS sitze
    FROM sitzanspruch_qpartei sp;

CREATE MATERIALIZED VIEW verbleibende_sitze_landesliste AS
    WITH RECURSIVE
        landeslisten_divisor AS (
            (SELECT zs.partei,
                    SUM(GREATEST(ROUND(zsl.anzahlstimmen / (zs.anzahlstimmen::numeric / svl.sitze)),
                                 mp.mindestsitze))        AS sitze_ll,
                    zs.anzahlstimmen::numeric / svl.sitze AS divisor,
                    zs.anzahlstimmen::numeric / svl.sitze AS next_divisor
             FROM zweitstimmen_qpartei_bundesland zsl,
                  zweitstimmen_qpartei zs,
                  sitze_nach_erhoehung svl,
                  mindestsitze_qpartei_bundesland mp
             WHERE zsl.partei = zs.partei
               AND zs.partei = svl.partei
               AND mp.partei = zs.partei
               AND mp.land = zsl.land
             GROUP BY zs.partei,
                      zs.anzahlstimmen,
                      svl.sitze)
            UNION ALL
            (SELECT ld.partei,
                    (SELECT SUM(GREATEST(ROUND(zs.anzahlstimmen / ld.next_divisor), mp.mindestsitze))
                     FROM mindestsitze_qpartei_bundesland mp,
                          zweitstimmen_qpartei_bundesland zs
                     WHERE zs.land = mp.land
                       AND zs.partei = mp.partei
                       AND zs.partei = ld.partei),
                    ld.next_divisor,
                    (CASE
                         WHEN ld.sitze_ll > svl.sitze THEN
                             (SELECT AVG(dk.divisor)
                              FROM (SELECT zs.anzahlstimmen /
                                           (ROUND(zs.anzahlstimmen / ld.next_divisor) - dk.divisor - 0.5) AS divisor
                                    FROM zweitstimmen_qpartei_bundesland zs,
                                         divisor_kandidat dk,
                                         mindestsitze_qpartei_bundesland mp
                                    WHERE zs.partei = ld.partei
                                      AND mp.partei = zs.partei
                                      AND mp.land = zs.land
                                      AND ROUND(zs.anzahlstimmen / ld.next_divisor) - mp.mindestsitze > dk.divisor
                                    ORDER BY divisor
                                    LIMIT 2) AS dk)
                         WHEN ld.sitze_ll < svl.sitze THEN
                             (SELECT AVG(dk.divisor)
                              FROM (SELECT zs.anzahlstimmen /
                                           (ROUND(zs.anzahlstimmen / ld.next_divisor) + dk.divisor + 0.5) AS divisor
                                    FROM zweitstimmen_qpartei_bundesland zs,
                                         divisor_kandidat dk
                                    WHERE zs.partei = ld.partei
                                    ORDER BY divisor DESC
                                    LIMIT 2) AS dk)
                         ELSE ld.next_divisor
                        END)
             FROM landeslisten_divisor ld,
                  sitze_nach_erhoehung svl
             WHERE ld.partei = svl.partei
               AND ld.sitze_ll != svl.sitze)),

        sitze_landesliste AS
            (SELECT zg.partei,
                    zg.land,
                    GREATEST(ROUND(zg.anzahlstimmen / d.divisor), mp.mindestsitze) AS sitze
             FROM landeslisten_divisor d,
                  sitze_nach_erhoehung svl,
                  zweitstimmen_qpartei_bundesland zg,
                  mindestsitze_qpartei_bundesland mp
             WHERE svl.sitze = d.sitze_ll
               AND d.partei = svl.partei
               AND zg.partei = svl.partei
               AND zg.partei = mp.partei
               AND zg.land = mp.land)
    SELECT vl.partei,
           vl.land,
           vl.sitze - dm.direktmandate AS verbleibend
    FROM sitze_landesliste vl,
         direktmandate_qpartei_bundesland dm
    WHERE vl.land = dm.land
      AND vl.partei = dm.partei;


CREATE MATERIALIZED VIEW landeslisten_ohne_direktmandate AS
    SELECT l.listenid,
           l.partei,
           l.land,
           lp.position,
           lp.kandidat
    FROM listenplatz lp,
         landesliste l
    WHERE lp.liste = l.listenid
      AND l.wahl = 20
      AND lp.kandidat NOT IN
          (SELECT kandidat
           FROM direktmandat dm);


CREATE MATERIALIZED VIEW listenmandate AS
    SELECT lo.listenid,
           lo.position,
           lo.kandidat,
           lo.land,
           lo.partei
    FROM landeslisten_ohne_direktmandate lo,
         verbleibende_sitze_landesliste vl
    WHERE lo.land = vl.land
      AND lo.partei = vl.partei
      AND (SELECT COUNT(*)
           FROM landeslisten_ohne_direktmandate lo2
           WHERE lo.partei = lo2.partei
             AND lo.land = lo2.land
             AND lo2.position < lo.position) < vl.verbleibend;

CREATE MATERIALIZED VIEW mandate AS
    SELECT k.vorname,
           k.nachname,
           'Direktmandat aus Wahlkreis ' || wk.nummer || ' - ' || wk.name AS grund,
           p.kuerzel as partei
    FROM kandidat k,
         direktmandat dm,
         wahlkreis wk,
         partei p
    WHERE k.kandid = dm.kandidat
      AND dm.wahlkreis = wk.wkid
      AND wk.wahl = 20
      AND dm.partei = p.parteiid
    UNION
    SELECT k.vorname,
           k.nachname,
           'Landeslistenmandat von Listenplatz ' || lm.position || ' in ' || bl.name AS grund,
           p.kuerzel as partei
    FROM kandidat k,
         listenmandate lm,
         bundesland bl,
         partei p
    WHERE k.kandid = lm.kandidat
      AND lm.land = bl.landid
      AND lm.partei = p.parteiid;
