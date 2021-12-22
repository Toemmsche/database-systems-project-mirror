DROP VIEW IF EXISTS ueberhang_qpartei_bundesland CASCADE;

CREATE VIEW ueberhang_qpartei_bundesland(wahl, land, partei, partei_farbe, ueberhang) AS
    WITH RECURSIVE
        direktkandidatur_nummeriert(wahlkreis, kandidat, partei, wk_rang) AS
            (SELECT dk.wahlkreis,
                    dk.kandidat,
                    dk.partei,
                    ROW_NUMBER() OVER (PARTITION BY dk.wahlkreis ORDER BY dk.anzahlstimmen DESC)
             FROM direktkandidatur dk),
        direktmandat(wahl, land, partei, wahlkreis, kandidat) AS
            (SELECT wk.wahl,
                    wk.land,
                    dkn.partei,
                    wk.wkid,
                    dkn.kandidat
             FROM direktkandidatur_nummeriert dkn,
                  wahlkreis wk
             WHERE dkn.wahlkreis = wk.wkid
               AND dkn.wk_rang = 1),
        zweitstimmen_partei_wahlkreis(wahl, wahlkreis, partei, anzahlstimmen) AS
            (SELECT wk.wahl, wk.wkid, ll.partei, SUM(ze.anzahlstimmen)
             FROM wahlkreis wk,
                  landesliste ll,
                  zweitstimmenergebnis ze
             WHERE wk.wkid = ze.wahlkreis
               AND ze.liste = ll.listenid
             GROUP BY wk.wahl, wk.wkid, ll.partei),
        zweitstimmen_partei_bundesland(wahl, land, partei, anzahlstimmen) AS
            (SELECT zpw.wahl, wk.land, zpw.partei, SUM(zpw.anzahlstimmen)
             FROM wahlkreis wk,
                  zweitstimmen_partei_wahlkreis zpw
             WHERE wk.wkid = zpw.wahlkreis
             GROUP BY zpw.wahl, wk.land, zpw.partei),
        zweitstimmen_partei(wahl, partei, anzahlstimmen) AS
            (SELECT zpb.wahl, zpb.partei, SUM(zpb.anzahlstimmen)
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
            (wahl, land, partei, anzahlstimmen)
            AS
            (SELECT *
             FROM zweitstimmen_partei_bundesland zpb
             WHERE zpb.partei IN (SELECT p.partei FROM qpartei p WHERE zpb.wahl = p.wahl)),
        direktmandate_qpartei_bundesland(wahl, land, partei, direktmandate) AS
            (SELECT dm.wahl, dm.land, p.partei, COUNT(*)
             FROM direktmandat dm,
                  qpartei p
             WHERE dm.wahl = p.wahl
               AND dm.partei = p.partei
             GROUP BY dm.wahl, dm.land, p.partei),
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
                    SUM(ROUND(b.bevoelkerung / (gb.bevoelkerung::DECIMAL / gs.anzahlsitze))),
                    SUM(b.bevoelkerung)::DECIMAL / gs.anzahlsitze,
                    SUM(b.bevoelkerung)::DECIMAL / gs.anzahlsitze
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
               AND sv.sitze = gs.anzahlsitze),
        sitze_bundesland(wahl, land, sitze, divisor) AS
            (SELECT b.wahl, b.land, ROUND(b.bevoelkerung::DECIMAL / d.divisor) AS sitze, d.divisor
             FROM bundesland_bevoelkerung b,
                  divisor d
             WHERE d.wahl = b.wahl),
        zweitstimmen_bundesland(wahl, land, anzahlstimmen) AS
            (SELECT zpb.wahl, zpb.land, SUM(zpb.anzahlstimmen)
             FROM zweitstimmen_qpartei_bundesland zpb
             GROUP BY zpb.wahl, zpb.land),
        laender_divisor(wahl, land, sitze_ld, divisor, next_divisor) AS
            (SELECT zbl.wahl,
                    zbl.land                                                                 AS land,
                    SUM(ROUND(zpb.anzahlstimmen / (zbl.anzahlstimmen::NUMERIC / sbl.sitze))) AS sitze_ld,
                    zbl.anzahlstimmen::NUMERIC / sbl.sitze                                   AS divisor,
                    zbl.anzahlstimmen::NUMERIC / sbl.sitze                                   AS next_divisor
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
               AND sbl.sitze = ld.sitze_ld),
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
                          AND sk.land = dm.land)
    SELECT mpb.wahl, bl.name, p.kuerzel, p.farbe, mpb.ueberhang
    FROM mindestsitze_qpartei_bundesland mpb,
         bundesland bl,
         partei p
    WHERE mpb.land = bl.landid
      AND mpb.partei = p.parteiid
      AND mpb.ueberhang > 0;

