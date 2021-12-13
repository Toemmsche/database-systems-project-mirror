DROP VIEW IF EXISTS divisor_kandidat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sitze_bundesland CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mindestsitze_qpartei_bundesland CASCADE;

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
            (SELECT 19, wk.land, SUM(wk.deutsche)
             FROM wahlkreis wk
             WHERE wk.wahl = 19
             GROUP BY wk.land
             UNION
             VALUES (20, 1,
                     2659792),
                    (20, 2,
                     1537766),
                    (20, 3,
                     7207587),
                    (20, 4,
                     548941),
                    (20, 5,
                     15415642),
                    (20, 6,
                     5222158),
                    (20, 7,
                     3610865),
                    (20, 8,
                     9313413),
                    (20, 9,
                     11328866),
                    (20, 10,
                     865191),
                    (20, 11,
                     2942960),
                    (20, 12,
                     2397701),
                    (20, 13,
                     1532412),
                    (20, 14,
                     3826905),
                    (20, 15,
                     2056177),
                    (20, 16,
                     1996822)),
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
CREATE MATERIALIZED VIEW mindestsitze_qpartei_bundesland (wahl, land, partei, mindestsitze, sitzkontingent, ueberhang) AS
    WITH RECURSIVE
        zweitstimmen_qpartei_bundesland(wahl, land, partei, anzahlstimmen) AS
            (SELECT *
             FROM zweitstimmen_partei_bundesland zpb
             WHERE zpb.partei IN (SELECT p.partei FROM qpartei p WHERE zpb.wahl = p.wahl)),
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
               AND sbl.sitze = ld.sitze_ld),
        direktmandate_qpartei_bundesland(wahl, land, partei, direktmandate) AS
            (SELECT dm.wahl, dm.land, p.partei, COUNT(dm.kandidatur)
             FROM direktmandat dm,
                  qpartei p
             WHERE dm.wahl = p.wahl
               AND dm.partei = p.partei
             GROUP BY dm.wahl, dm.land, p.partei)
    SELECT sk.wahl,
           sk.land,
           sk.partei,
           sk.sitzkontingent,
           GREATEST(COALESCE(dm.direktmandate, 0),
                    ROUND((sk.sitzkontingent + COALESCE(dm.direktmandate, 0)) / 2)) AS mindestsitze,
           (CASE
                WHEN COALESCE(dm.direktmandate, 0) > sk.sitzkontingent
                    THEN COALESCE(dm.direktmandate, 0) - sk.sitzkontingent
                ELSE 0
            END)                                                                    AS ueberhang
    FROM sitzkontingent_qpartei_bundesland sk
             LEFT OUTER JOIN
         direktmandate_qpartei_bundesland dm ON
                     sk.wahl = dm.wahl
                 AND sk.partei = dm.partei
                 AND sk.land = dm.land;

