DROP MATERIALIZED VIEW IF EXISTS mandat CASCADE;

--Mit 'Ueberhang' wird die 2. Normalform bewusst verletzt, damit Informationen kompakter abgespeichert werden können
CREATE MATERIALIZED VIEW mandat
            (wahl, land, partei, ist_direktmandat, wahlkreis, kandidatur, liste, position, kandidat, ueberhang_land) AS
    WITH RECURSIVE
        direktkandidatur_nummeriert(wahlkreis, partei, kandidatur, kandidat, wk_rang) AS
            (SELECT dk.wahlkreis,
                    dk.partei,
                    dk.direktid,
                    dk.kandidat,
                    ROW_NUMBER() OVER (PARTITION BY dk.wahlkreis ORDER BY dk.anzahlstimmen DESC)
             FROM direktkandidatur dk),
        direktmandat(wahl, land, partei, wahlkreis, kandidatur, kandidat) AS
            (SELECT wk.wahl,
                    wk.land,
                    dkn.partei,
                    wk.wkid,
                    dkn.kandidatur,
                    dkn.kandidat
             FROM direktkandidatur_nummeriert dkn,
                  wahlkreis wk
             WHERE dkn.wahlkreis = wk.wkid
               AND dkn.wk_rang = 1),
        zweitstimmen_partei_wahlkreis(wahlkreis, partei, anzahlstimmen) AS
            (SELECT wk.wkid, ll.partei, SUM(ze.anzahlstimmen)
             FROM wahlkreis wk,
                  landesliste ll,
                  zweitstimmenergebnis ze
             WHERE wk.wkid = ze.wahlkreis
               AND ze.liste = ll.listenid
             GROUP BY wk.wkid, ll.partei),
        zweitstimmen_partei_bundesland(wahl, land, partei, anzahlstimmen) AS
            (SELECT wk.wahl, wk.land, zpw.partei, SUM(zpw.anzahlstimmen)::INTEGER
             FROM wahlkreis wk,
                  zweitstimmen_partei_wahlkreis zpw
             WHERE wk.wkid = zpw.wahlkreis
             GROUP BY wk.wahl, wk.land, zpw.partei),
        zweitstimmen_partei(wahl, partei, anzahlstimmen) AS
            (SELECT zpb.wahl, zpb.partei, SUM(zpb.anzahlstimmen)::INTEGER
             FROM zweitstimmen_partei_bundesland zpb
             GROUP BY zpb.wahl, zpb.partei),
        zweitstimmen(wahl, anzahlstimmen) AS
            (SELECT zp.wahl, SUM(zp.anzahlstimmen)
             FROM zweitstimmen_partei zp
             GROUP BY zp.wahl),
        qpartei(wahl, partei) AS
            --5% Hürde
            (SELECT zp.wahl, zp.partei
             FROM zweitstimmen_partei zp,
                  zweitstimmen z
             WHERE zp.wahl = z.wahl
               AND zp.anzahlstimmen >= 0.05 * z.anzahlstimmen
             UNION
             --3 Direktmandate
             SELECT dm.wahl, dm.partei
             FROM direktmandat dm
             GROUP BY dm.wahl, dm.partei
             HAVING COUNT(*) >= 3
             UNION
             --Nationale Minderheit
             SELECT btw.nummer, p.parteiid
             FROM bundestagswahl btw,
                  partei p
             WHERE p.nationaleminderheit),
        zweitstimmen_qpartei_bundesland
            (wahl, land, partei, anzahlstimmen) AS
            (SELECT zpb.*
             FROM zweitstimmen_partei_bundesland zpb,
                  qpartei qp
             WHERE zpb.wahl = qp.wahl
               AND zpb.partei = qp.partei),
        zweitstimmen_qpartei(wahl, partei, anzahlstimmen) AS
            (SELECT zpb.wahl, zpb.partei, SUM(anzahlstimmen)
             FROM zweitstimmen_qpartei_bundesland zpb
             GROUP BY zpb.wahl, zpb.partei),
        direktmandate_qpartei_bundesland(wahl, land, partei, direktmandate) AS
            (SELECT dm.wahl, dm.land, p.partei, COUNT(*)::INTEGER
             FROM direktmandat dm,
                  qpartei p
             WHERE dm.wahl = p.wahl
               AND dm.partei = p.partei
             GROUP BY dm.wahl, dm.land, p.partei),
        gesamtsitze(wahl, anzahlsitze) AS
            (SELECT wahl, 2 * COUNT(*)::INTEGER
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
        divisor_kandidat(divisor) AS
                (VALUES (0), (1)),
        bund_divisor(wahl, divisor) AS
            (SELECT gs.wahl,
                    divisorverfahren(gs.anzahlsitze, ARRAY_AGG(bb.bevoelkerung))
             FROM gesamtsitze gs,
                  bundesland_bevoelkerung bb
             WHERE bb.wahl = gs.wahl
             GROUP BY gs.anzahlsitze, gs.wahl),
        sitze_bundesland(wahl, land, sitze, divisor) AS
            (SELECT b.wahl, b.land, ROUND(b.bevoelkerung::DECIMAL / bd.divisor)::INTEGER AS sitze, bd.divisor
             FROM bundesland_bevoelkerung b,
                  bund_divisor bd
             WHERE bd.wahl = b.wahl),
        laender_divisor(wahl, land, divisor) AS (
            SELECT zpb.wahl, zpb.land, divisorverfahren(sbl.sitze, ARRAY_AGG(zpb.anzahlstimmen))
            FROM zweitstimmen_qpartei_bundesland zpb,
                 sitze_bundesland sbl
            WHERE sbl.wahl = zpb.wahl
              AND sbl.land = zpb.land
            GROUP BY zpb.wahl, zpb.land, sbl.sitze
        ),
        sitzkontingent_qpartei_bundesland (wahl, land, partei, sitzkontingent) AS
            (SELECT zpb.wahl,
                    zpb.land,
                    zpb.partei,
                    ROUND(zpb.anzahlstimmen / ld.divisor) AS sitzkontingent
             FROM laender_divisor ld,
                  zweitstimmen_qpartei_bundesland zpb,
                  sitze_bundesland sbl
             WHERE zpb.wahl = ld.wahl
               AND zpb.wahl = sbl.wahl
               AND ld.land = zpb.land
               AND zpb.land = sbl.land),
        mindestsitze_qpartei_bundesland
            (wahl, land, partei, sitzkontingent, direktmandate, mindestsitze, ueberhang) AS
            (SELECT sk.wahl,
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
                        END                       AS mindestsitze,
/*
==================================================================================================================
==================================================================================================================
*/
                    CASE
                        WHEN COALESCE(dm.direktmandate, 0) > sk.sitzkontingent
                            THEN COALESCE(dm.direktmandate, 0) - sk.sitzkontingent
                        ELSE 0
                        END                       AS ueberhang
             FROM sitzkontingent_qpartei_bundesland sk
                      LEFT OUTER JOIN
                  direktmandate_qpartei_bundesland dm ON
                              sk.wahl = dm.wahl
                          AND sk.partei = dm.partei
                          AND sk.land = dm.land),
        sitzanspruch_qpartei(wahl, partei, sitzkontingent, mindestsitzanspruch, drohender_ueberhang, anzahlstimmen) AS
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
                                    (SELECT sp.anzahlstimmen / (sp.sitzkontingent::NUMERIC - 0.5) AS divisor
                                     FROM sitzanspruch_qpartei sp
                                     WHERE sp.wahl = btw.nummer
                                     ORDER BY divisor ASC
                                     LIMIT 1),
                                    (WITH ueberhang(ueberhang)
                                              AS (VALUES (0.0), (1.0), (2.0), (3.0))
                                     SELECT sp.anzahlstimmen /
                                            (sp.mindestsitzanspruch::NUMERIC - u.ueberhang - 0.5) AS divisor
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
                    (SELECT zp.anzahlstimmen / (ROUND(zp.anzahlstimmen / d.obergrenze) + 0.5) AS untergrenze
                     FROM zweitstimmen_qpartei zp,
                          divisor_obergrenze d
                     WHERE zp.wahl = btw.nummer
                       AND zp.wahl = d.wahl
                     ORDER BY untergrenze DESC
                     LIMIT 1) AS untergrenze
             FROM bundestagswahl btw),
        endgueltiger_divisor(wahl, divisor) AS
            (SELECT ud.wahl, (ud.untergrenze + od.obergrenze) / 2 AS divisor
             FROM divisor_untergrenze ud,
                  divisor_obergrenze od
             WHERE ud.wahl = od.wahl),
        sitze_nach_erhoehung(wahl, partei, sitze) AS
            (SELECT sp.wahl,
                    sp.partei,
                    GREATEST(ROUND(sp.anzahlstimmen / ed.divisor),
                             sp.mindestsitzanspruch) AS sitze
             FROM sitzanspruch_qpartei sp,
                  endgueltiger_divisor ed
             WHERE sp.wahl = ed.wahl),
        landeslisten_divisor(wahl, partei, sitze_ll_sum, divisor, next_divisor) AS (
            (SELECT zp.wahl,
                    zp.partei,
                    SUM(GREATEST(ROUND(zpb.anzahlstimmen / (zp.anzahlstimmen::NUMERIC / svl.sitze)),
                                 mp.mindestsitze))        AS sitze_ll_sum,
                    zp.anzahlstimmen::NUMERIC / svl.sitze AS divisor,
                    zp.anzahlstimmen::NUMERIC / svl.sitze AS next_divisor
             FROM zweitstimmen_qpartei zp,
                  zweitstimmen_qpartei_bundesland zpb,
                  sitze_nach_erhoehung svl,
                  mindestsitze_qpartei_bundesland mp
             WHERE zp.wahl = zpb.wahl
               AND zp.wahl = svl.wahl
               AND zp.wahl = mp.wahl
               AND zp.partei = zpb.partei
               AND zp.partei = svl.partei
               AND zp.partei = mp.partei
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
                    (sll.sitze_ll - COALESCE(dm.direktmandate, 0))::INTEGER
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
             FROM landeslisten_ohne_direktmandate lo),
        listenmandat (wahl, land, partei, liste, position, kandidat) AS
            (SELECT lo.wahl,
                    lo.land,
                    lo.partei,
                    lo.liste,
                    lo.position,
                    lo.kandidat
             FROM landeslisten_ohne_direktmandate_nummeriert lo,
                  verbleibende_sitze_landesliste vsll
             WHERE lo.wahl = vsll.wahl
               AND lo.land = vsll.land
               AND lo.partei = vsll.partei
               AND lo.neue_position <= vsll.verbleibende_sitze)
    SELECT dm.wahl,
           dm.land,
           dm.partei,
           TRUE,
           dm.wahlkreis,
           dm.kandidatur,
           NULL,
           NULL,
           dm.kandidat,
           mp.ueberhang
    FROM direktmandat dm,
         mindestsitze_qpartei_bundesland mp
    WHERE dm.wahl = mp.wahl
      AND dm.land = mp.land
      AND dm.partei = mp.partei
    UNION
    SELECT lm.wahl,
           lm.land,
           lm.partei,
           FALSE,
           NULL,
           NULL,
           lm.liste,
           lm.position,
           lm.kandidat,
           mp.ueberhang
    FROM listenmandat lm,
         mindestsitze_qpartei_bundesland mp
    WHERE lm.wahl = mp.wahl
      AND lm.land = mp.land
      AND lm.partei = mp.partei;
