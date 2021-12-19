DROP VIEW IF EXISTS divisor_kandidat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mindestsitze_qpartei_bundesland CASCADE;
DROP VIEW IF EXISTS sitzanspruch_qpartei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_nach_erhoehung CASCADE;
DROP MATERIALIZED VIEW IF EXISTS listenmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mandat CASCADE;

CREATE VIEW divisor_kandidat(divisor) AS
    VALUES (0),
           (1);

--Anzahl an sitze, die dem jeweiligen Bundesland zustehen
CREATE MATERIALIZED VIEW sitze_bundesland(wahl, land, sitze, divisor) AS
    WITH RECURSIVE
        gesamtsitze(wahl, anzahlsitze) AS
            (SELECT wahl, 2 * COUNT(*)
             FROM wahlkreis
             GROUP BY wahl),
        bundesland_bevoelkerung(wahl, land, bevoelkerung) AS
            (VALUES (19, 1, 2673803),
                    (19, 2, 1525090),
                    (19, 3, 7278789),
                    (19, 4, 568510),
                    (19, 5, 15707569),
                    (19, 6, 5281198),
                    (19, 7, 3661245),
                    (19, 8, 9365001),
                    (19, 9, 11362245),
                    (19, 10, 899748),
                    (19, 11, 2975745),
                    (19, 12, 2391746),
                    (19, 13, 1548400),
                    (19, 14, 3914671),
                    (19, 15, 2145671),
                    (19, 16, 2077901)
             UNION
             VALUES (20, 1, 2659792),
                    (20, 2, 1537766),
                    (20, 3, 7207587),
                    (20, 4, 548941),
                    (20, 5, 15415642),
                    (20, 6, 5222158),
                    (20, 7, 3610865),
                    (20, 8, 9313413),
                    (20, 9, 11328866),
                    (20, 10, 865191),
                    (20, 11, 2942960),
                    (20, 12, 2397701),
                    (20, 13, 1532412),
                    (20, 14, 3826905),
                    (20, 15, 2056177),
                    (20, 16, 1996822)),
        gesamtbevoelkerung(wahl, bevoelkerung) AS
            (SELECT wahl, SUM(bevoelkerung)
             FROM bundesland_bevoelkerung
             GROUP BY wahl),
        sitzverteilung(wahl, sitze, divisor, next_divisor) AS
            (SELECT b.wahl,
                    SUM(ROUND(b.bevoelkerung / (gb.bevoelkerung::decimal / gs.anzahlsitze))),
                    SUM(b.bevoelkerung)::decimal / gs.anzahlsitze,
                    SUM(b.bevoelkerung)::decimal / gs.anzahlsitze
             FROM bundesland_bevoelkerung b,
                  gesamtsitze gs,
                  gesamtbevoelkerung gb
             WHERE b.wahl = gs.wahl
               AND b.wahl = gb.wahl
             GROUP BY b.wahl, gs.anzahlsitze
             UNION ALL
             (SELECT sv.wahl,
                     (SELECT SUM(ROUND(b.bevoelkerung / sv.next_divisor))
                      FROM bundesland_bevoelkerung b
                      WHERE b.wahl = sv.wahl),
                     sv.next_divisor,
                     CASE
                         WHEN sitze < gs.anzahlsitze THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT b.bevoelkerung /
                                           (ROUND(b.bevoelkerung / sv.next_divisor) + 0.5 + dk.divisor) AS divisor
                                    FROM bundesland_bevoelkerung b,
                                         divisor_kandidat dk
                                    WHERE b.wahl = sv.wahl
                                    ORDER BY divisor DESC
                                    LIMIT 2) AS d)
                         WHEN sitze > gs.anzahlsitze THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT b.bevoelkerung /
                                           (ROUND(b.bevoelkerung / sv.next_divisor) - 0.5 - dk.divisor) AS divisor
                                    FROM bundesland_bevoelkerung b,
                                         divisor_kandidat dk
                                    WHERE b.wahl = sv.wahl
                                    ORDER BY divisor
                                    LIMIT 2) AS d)
                         ELSE sv.next_divisor
                     END
              FROM sitzverteilung sv,
                   gesamtsitze gs
              WHERE sv.wahl = gs.wahl
                AND sv.sitze != gs.anzahlsitze)),
        divisor AS
            (SELECT sv.wahl, sv.divisor
             FROM sitzverteilung sv,
                  gesamtsitze gs
             WHERE sv.wahl = gs.wahl
               AND sv.sitze = gs.anzahlsitze)
    SELECT b.wahl, b.land, ROUND(b.bevoelkerung::DECIMAL / d.divisor) AS sitze, d.divisor
    FROM bundesland_bevoelkerung b,
         divisor d
    WHERE d.wahl = b.wahl;


--Anzahl der Sitze die einer Partei mindestens pro Bundesland zustehen.
--Zusätzlich dazu wird das Sitzekontingent (nach Zweitstimmen) und der Überhang berechnet
CREATE MATERIALIZED VIEW mindestsitze_qpartei_bundesland
            (wahl, land, partei, sitzkontingent, direktmandate, mindestsitze, ueberhang) AS
    WITH RECURSIVE
        zweitstimmen_bundesland(wahl, land, anzahlstimmen) AS
            (SELECT zpb.wahl, zpb.land, SUM(zpb.anzahlstimmen)
             FROM zweitstimmen_qpartei_bundesland zpb
             GROUP BY zpb.wahl, zpb.land),
        laender_divisor(wahl, land, sitze_ld, divisor, next_divisor) AS
            (SELECT zbl.wahl,
                    zbl.land                                                                 AS land,
                    SUM(ROUND(zpb.anzahlstimmen / (zbl.anzahlstimmen::numeric / sbl.sitze))) AS sitze_ld,
                    zbl.anzahlstimmen::numeric / sbl.sitze                                   AS divisor,
                    zbl.anzahlstimmen::numeric / sbl.sitze                                   AS next_divisor
             FROM zweitstimmen_qpartei_bundesland zpb,
                  zweitstimmen_bundesland zbl,
                  sitze_bundesland sbl
             WHERE zpb.wahl = zbl.wahl
               AND zpb.wahl = sbl.wahl
               AND zpb.land = zbl.land
               AND zpb.land = sbl.land
             GROUP BY zbl.wahl,
                      zbl.land,
                      zbl.anzahlstimmen,
                      sbl.sitze
             UNION ALL
             (SELECT zbl.wahl,
                     zbl.land,
                     (SELECT SUM(ROUND(zpb.anzahlstimmen / ld.next_divisor))
                      FROM zweitstimmen_qpartei_bundesland zpb
                      WHERE zpb.wahl = ld.wahl
                        AND zpb.land = ld.land) AS sitze_ld,
                     ld.next_divisor,
                     CASE
                         WHEN sbl.sitze < ld.sitze_ld THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT zpb.anzahlstimmen /
                                           (ROUND(zpb.anzahlstimmen / ld.next_divisor) - 0.5 - dk.divisor) AS divisor
                                    FROM divisor_kandidat dk,
                                         zweitstimmen_qpartei_bundesland zpb
                                    WHERE zpb.wahl = zbl.wahl
                                      AND zpb.land = zbl.land
                                      AND ROUND(zpb.anzahlstimmen / ld.next_divisor) > dk.divisor
                                    ORDER BY divisor
                                    LIMIT 2) AS d)
                         WHEN sbl.sitze > ld.sitze_ld THEN
                             (SELECT AVG(d.divisor)
                              FROM (SELECT zpb.anzahlstimmen /
                                           (ROUND(zpb.anzahlstimmen / ld.next_divisor) + 0.5 + dk.divisor) AS divisor
                                    FROM divisor_kandidat dk,
                                         zweitstimmen_qpartei_bundesland zpb
                                    WHERE zpb.wahl = zbl.wahl
                                      AND zpb.land = zbl.land
                                    ORDER BY divisor DESC
                                    LIMIT 2) AS d)
                         ELSE ld.next_divisor
                     END
              FROM zweitstimmen_bundesland zbl,
                   laender_divisor ld,
                   sitze_bundesland sbl
              WHERE zbl.wahl = sbl.wahl
                AND zbl.wahl = ld.wahl
                AND zbl.land = ld.land
                AND zbl.land = sbl.land
                AND sbl.sitze != ld.sitze_ld)
            ),
        sitzkontingent_qpartei_bundesland (wahl, land, partei, sitzkontingent) AS
            (SELECT zpb.wahl,
                    zpb.land,
                    zpb.partei,
                    ROUND(zpb.anzahlstimmen / ld.divisor) AS sitzkontingent,
                    ld.sitze_ld,
                    sbl.sitze,
                    ld.divisor,
                    zpb.anzahlstimmen
             FROM laender_divisor ld,
                  zweitstimmen_qpartei_bundesland zpb,
                  sitze_bundesland sbl
             WHERE zpb.wahl = ld.wahl
               AND zpb.wahl = sbl.wahl
               AND ld.land = zpb.land
               AND zpb.land = sbl.land
               AND sbl.sitze = ld.sitze_ld)
    SELECT sk.wahl,
           sk.land,
           sk.partei,
           sk.sitzkontingent,
           COALESCE(dm.direktmandate, 0) AS direktmandate,
        /*
==================================================================================================================
        FALLUNTERSCHEIDUNG 2021 VS 2017:
        In 2017 wird die Mindestsitzzahl als das Maximum aus Direktmandate und Sitzkontingente gebildet.
        In 2021 wird die Mindestsitzzahl als Durchschnitt aus Direktmandate und Sitzkontingente gebildet.
==================================================================================================================
         */
           CASE
               WHEN sk.wahl = 20
                   THEN GREATEST(COALESCE(dm.direktmandate, 0),
                                 ROUND((sk.sitzkontingent + COALESCE(dm.direktmandate, 0)) / 2))
               ELSE GREATEST(COALESCE(dm.direktmandate, 0), (sk.sitzkontingent))
           END                           AS mindestsitze,
/*
==================================================================================================================
==================================================================================================================
*/
           CASE
               WHEN COALESCE(dm.direktmandate, 0) > sk.sitzkontingent
                   THEN COALESCE(dm.direktmandate, 0) - sk.sitzkontingent
               ELSE 0
           END                           AS ueberhang
    FROM sitzkontingent_qpartei_bundesland sk
             LEFT OUTER JOIN
         direktmandate_qpartei_bundesland dm ON
                     sk.wahl = dm.wahl
                 AND sk.partei = dm.partei
                 AND sk.land = dm.land;

CREATE MATERIALIZED VIEW sitze_nach_erhoehung(wahl, partei, sitze) AS
    WITH sitzanspruch_qpartei(wahl, partei, sitzkontingent, mindestsitzanspruch, drohender_ueberhang, anzahlstimmen) AS
             (SELECT zp.wahl,
                     zp.partei,
                     SUM(mp.sitzkontingent)                                 AS sitzkontingent,
                     GREATEST(SUM(mp.sitzkontingent), SUM(mp.mindestsitze)) AS mindestsitzanspruch,
                     SUM(mp.ueberhang)                                      AS drohender_ueberhang,
                     zp.anzahlstimmen
              FROM zweitstimmen_qpartei zp,
                   mindestsitze_qpartei_bundesland mp
              WHERE zp.wahl = mp.wahl
                AND mp.partei = zp.partei
              GROUP BY zp.wahl, zp.partei, zp.anzahlstimmen),
         divisor_obergrenze(wahl, obergrenze) AS
             (SELECT btw.nummer,
                  /*
    ==================================================================================================================
         FALLUNTERSCHEIDUNG 2021 VS 2017:
         In 2017 werden alle Überhangsmandate ausgeglichen.
         In 2021 werden die ersten drei Überhangsmandate NICHT ausgeglichen und es wird mit dem Mindestsitzanspruch
         gerechnet.
    ==================================================================================================================
          */
                     CASE
                         WHEN btw.nummer = 20 THEN
                             LEAST(
                                     (SELECT sp.anzahlstimmen / (sp.sitzkontingent::numeric - 0.5) AS divisor
                                      FROM sitzanspruch_qpartei sp
                                      WHERE sp.wahl = btw.nummer
                                      ORDER BY divisor ASC
                                      LIMIT 1),
                                     (WITH ueberhang(ueberhang)
                                               AS (VALUES (0.0), (1.0), (2.0), (3.0))
                                      SELECT sp.anzahlstimmen /
                                             (sp.mindestsitzanspruch::numeric - u.ueberhang - 0.5) AS divisor
                                      FROM sitzanspruch_qpartei sp,
                                           ueberhang u
                                      WHERE sp.wahl = btw.nummer
                                        AND sp.drohender_ueberhang > u.ueberhang
                                      ORDER BY divisor ASC
                                      OFFSET 3 LIMIT 1)
                                 )
                         ELSE (SELECT sp.anzahlstimmen / (sp.mindestsitzanspruch::NUMERIC - 0.5) AS divisor
                               FROM sitzanspruch_qpartei sp
                               WHERE sp.wahl = btw.nummer
                               ORDER BY divisor ASC
                               LIMIT 1)
                     END AS obergrenze
                  /*
      ==================================================================================================================
      ==================================================================================================================
                */
              FROM bundestagswahl btw),
         divisor_untergrenze(wahl, untergrenze) AS
             (SELECT btw.nummer,
                     (SELECT zs.anzahlstimmen / (ROUND(zs.anzahlstimmen / d.obergrenze) + 0.5) AS untergrenze
                      FROM zweitstimmen_qpartei zs,
                           divisor_obergrenze d
                      WHERE zs.wahl = btw.nummer
                        AND zs.wahl = d.wahl
                      ORDER BY untergrenze DESC
                      LIMIT 1) AS untergrenze
              FROM bundestagswahl btw),
         endgueltiger_divisor(wahl, divisor) AS
             (SELECT ud.wahl, (ud.untergrenze + od.obergrenze) / 2 AS divisor
              FROM divisor_untergrenze ud,
                   divisor_obergrenze od
              WHERE ud.wahl = od.wahl)
    SELECT sp.wahl,
           sp.partei,
           GREATEST(ROUND(sp.anzahlstimmen / ed.divisor),
                    sp.mindestsitzanspruch) AS sitze
    FROM sitzanspruch_qpartei sp,
         endgueltiger_divisor ed
    WHERE sp.wahl = ed.wahl;

CREATE MATERIALIZED VIEW listenmandat (wahl, liste, position, kandidat, land, partei) AS
    WITH RECURSIVE
        landeslisten_divisor(wahl, partei, sitze_ll_sum, divisor, next_divisor) AS (
            (SELECT zp.wahl,
                    zp.partei,
                    SUM(GREATEST(ROUND(zpb.anzahlstimmen / (zp.anzahlstimmen::numeric / svl.sitze)),
                                 mp.mindestsitze))        AS sitze_ll_sum,
                    zp.anzahlstimmen::numeric / svl.sitze AS divisor,
                    zp.anzahlstimmen::numeric / svl.sitze AS next_divisor
             FROM zweitstimmen_qpartei zp,
                  zweitstimmen_qpartei_bundesland zpb,
                  sitze_nach_erhoehung svl,
                  mindestsitze_qpartei_bundesland mp
             WHERE zp.wahl = zpb.wahl
               AND zp.wahl = svl.wahl
               AND zp.wahl = mp.wahl
               AND zpb.partei = zp.partei
               AND zp.partei = svl.partei
               AND mp.partei = zp.partei
               AND mp.land = zpb.land
             GROUP BY zp.wahl,
                      zp.partei,
                      zp.anzahlstimmen,
                      svl.sitze)
            UNION
            (SELECT lld.wahl,
                    lld.partei,
                    (SELECT SUM(GREATEST(ROUND(zpb.anzahlstimmen / lld.next_divisor), mp.mindestsitze))
                     FROM zweitstimmen_qpartei_bundesland zpb,
                          mindestsitze_qpartei_bundesland mp
                     WHERE lld.wahl = zpb.wahl
                       AND lld.wahl = mp.wahl
                       AND zpb.land = mp.land
                       AND lld.partei = zpb.partei
                       AND lld.partei = mp.partei),
                    lld.next_divisor,
                    (CASE
                         WHEN lld.sitze_ll_sum > svl.sitze THEN
                             (SELECT AVG(dk.divisor)
                              FROM (SELECT zpb.anzahlstimmen /
                                           (ROUND(zpb.anzahlstimmen / lld.next_divisor) - dk.divisor - 0.5) AS divisor
                                    FROM zweitstimmen_qpartei_bundesland zpb,
                                         divisor_kandidat dk,
                                         mindestsitze_qpartei_bundesland mp
                                    WHERE lld.wahl = zpb.wahl
                                      AND lld.wahl = mp.wahl
                                      AND lld.partei = zpb.partei
                                      AND lld.partei = mp.partei
                                      AND mp.land = zpb.land
                                        /*
==================================================================================================================
                                        FALLUNTERSCHEIDUNG 2021 VS 2017:
                                        In 2017 muss die Anzahl der gewonnen Direktmandate berücksichtigt werden
                                        In 2021 muss die Anzahl der Mindestsitze berücksichtigt werden.
==================================================================================================================
*/
                                      AND ((lld.wahl = 20 AND
                                            ROUND(zpb.anzahlstimmen / lld.next_divisor) - mp.mindestsitze >
                                            dk.divisor) OR (lld.wahl = 19 AND
                                                            ROUND(zpb.anzahlstimmen / lld.next_divisor) -
                                                            mp.direktmandate > dk.divisor))
                                        /*
==================================================================================================================
==================================================================================================================
*/
                                    ORDER BY divisor
                                    LIMIT 2)
                                       AS dk)
                         WHEN lld.sitze_ll_sum < svl.sitze THEN
                             (SELECT AVG(dk.divisor)
                              FROM (SELECT zpb.anzahlstimmen /
                                           (ROUND(zpb.anzahlstimmen / lld.next_divisor) + dk.divisor + 0.5) AS divisor
                                    FROM zweitstimmen_qpartei_bundesland zpb,
                                         divisor_kandidat dk
                                    WHERE lld.wahl = zpb.wahl
                                      AND zpb.partei = lld.partei
                                    ORDER BY divisor DESC
                                    LIMIT 2) AS dk)
                         ELSE lld.next_divisor
                     END)
             FROM landeslisten_divisor lld,
                  sitze_nach_erhoehung svl
             WHERE lld.wahl = svl.wahl
               AND lld.partei = svl.partei
               AND lld.sitze_ll_sum != svl.sitze)),
        sitze_landesliste (wahl, partei, land, sitze_ll) AS
            (SELECT lld.wahl,
                    lld.partei,
                    zpb.land,
                    GREATEST(ROUND(zpb.anzahlstimmen / lld.divisor), mp.mindestsitze),
                    lld.divisor
             FROM landeslisten_divisor lld,
                  sitze_nach_erhoehung svl,
                  zweitstimmen_qpartei_bundesland zpb,
                  mindestsitze_qpartei_bundesland mp
             WHERE lld.wahl = svl.wahl
               AND lld.wahl = zpb.wahl
               AND lld.wahl = mp.wahl
               AND svl.sitze = lld.sitze_ll_sum
               AND lld.partei = svl.partei
               AND lld.partei = zpb.partei
               AND lld.partei = mp.partei
               AND zpb.land = mp.land),
        verbleibende_sitze_landesliste(wahl, partei, land, verbleibende_sitze) AS
            (SELECT sll.wahl,
                    sll.partei,
                    sll.land,
                    sll.sitze_ll - COALESCE(dm.direktmandate, 0)
             FROM sitze_landesliste sll
                      LEFT OUTER JOIN
                  direktmandate_qpartei_bundesland dm ON
                              sll.wahl = dm.wahl
                          AND sll.land = dm.land
                          AND sll.partei = dm.partei),
        landeslisten_ohne_direktmandate(wahl, liste, partei, land, position, kandidat) AS
            /*
==================================================================================================================
        FALLUNTERSCHEIDUNG 2021 VS 2017:
        In 2017 können die Landeslisten ohne direktmandate NICHT ermittelt werden.
        In 2021 können die Landeslisten ohne direktmandate ermittelt werden.
==================================================================================================================
*/
            ((SELECT 20,
                     ll.listenid,
                     ll.partei,
                     ll.land,
                     lp.position,
                     lp.kandidat
              FROM listenplatz lp,
                   landesliste ll
              WHERE ll.wahl = 20
                AND ll.listenid = lp.liste
                AND lp.kandidat NOT IN
                    (SELECT dm.kandidat
                     FROM direktmandat dm
                     WHERE dm.wahl = 20))
             UNION
             (SELECT 19,
                     ll.listenid,
                     ll.partei,
                     ll.land,
                     GENERATE_SERIES(1, vsll.verbleibende_sitze),
                     NULL
              FROM landesliste ll,
                   verbleibende_sitze_landesliste vsll
              WHERE ll.wahl = 19
                AND vsll.wahl = 19
                AND ll.partei = vsll.partei
                AND ll.land = vsll.land)),
        /*
==================================================================================================================
==================================================================================================================
*/
        landeslisten_ohne_direktmandate_nummeriert(wahl, liste, partei, land, position, kandidat, neue_position) AS
            (SELECT lo.*, ROW_NUMBER() OVER (PARTITION BY lo.liste ORDER BY lo.position ASC)
             FROM landeslisten_ohne_direktmandate lo)
    SELECT lo.wahl,
           lo.liste,
           lo.position,
           lo.kandidat,
           lo.land,
           lo.partei
    FROM landeslisten_ohne_direktmandate_nummeriert lo,
         verbleibende_sitze_landesliste vsll
    WHERE lo.wahl = vsll.wahl
      AND lo.land = vsll.land
      AND lo.partei = vsll.partei
      AND lo.neue_position <= vsll.verbleibende_sitze;

CREATE MATERIALIZED VIEW mandat(wahl, kandidat, grund, partei) AS
    SELECT dm.wahl,
           dm.kandidat,
           'Direktmandat aus Wahlkreis ' || wk.nummer || ' - ' || wk.name AS grund,
           p.parteiid                                                     AS partei
    FROM direktmandat dm,
         wahlkreis wk,
         partei p
    WHERE dm.wahl = wk.wahl
      AND dm.wahlkreis = wk.wkid
      AND dm.partei = p.parteiid
    UNION
    SELECT lm.wahl,
           lm.kandidat,
           'Landeslistenmandat von Listenplatz ' || lm.position || ' in ' || bl.name AS grund,
           p.parteiid                                                                AS partei
    FROM listenmandat lm,
         bundesland bl,
         partei p
    WHERE lm.land = bl.landid
      AND lm.partei = p.parteiid;

