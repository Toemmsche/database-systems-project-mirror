DROP MATERIALIZED VIEW IF EXISTS vorsprung_direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS kleinster_vorsprung_partei CASCADE;
DROP MATERIALIZED VIEW IF EXISTS rueckstand_direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS kleinster_rueckstand_partei CASCADE;

--Absoluter Unterschied in Erststimmenanteil zwischen Wahlkreissieger und dem Zweitplazierten
CREATE MATERIALIZED VIEW vorsprung_direktmandat AS
    WITH vorsprung AS
             (SELECT wkid                                                                             AS wahlkreis,
                     (MAX(anzahlstimmen) - MIN(anzahlstimmen))::decimal / (SELECT SUM(anzahlstimmen)
                                                                           FROM direktkandidatur
                                                                           WHERE wahlkreis = wk.wkid) AS vorsprung_prozent
              FROM wahlkreis wk,
                   direktkandidatur dk
              WHERE wk.wahl = (SELECT * FROM wahlauswahl)
                AND dk.wahlkreis = wk.wkid
                AND dk.direktid IN (
                  SELECT dk2.direktid
                  FROM direktkandidatur dk2
                  WHERE dk2.wahlkreis = wk.wkid
                  ORDER BY dk2.anzahlstimmen DESC
                  LIMIT 2
              )
              GROUP BY wk.wkid)
    --Partei ID dazuholen
    SELECT v.wahlkreis, dm.partei, v.vorsprung_prozent
    FROM vorsprung v,
         direktmandat dm
    WHERE v.wahlkreis = dm.wahlkreis;

--Die 10 knappsten Wahlkreissiege (falls vorhanden)
CREATE MATERIALIZED VIEW kleinster_vorsprung_partei AS
    SELECT vd.partei, vd.wahlkreis, vd.vorsprung_prozent
    FROM vorsprung_direktmandat vd
    WHERE (SELECT COUNT(*)
           FROM vorsprung_direktmandat vd2
           WHERE vd.partei = vd2.partei
             AND vd2.vorsprung_prozent < vd.vorsprung_prozent) <= 9;

--Absoluter Unterschied in Erststimmenanteil zwischen Wahlkreisverlierern und Siegern
CREATE MATERIALIZED VIEW rueckstand_direktmandat AS
    SELECT wk.wkid                                                                      AS wahlkreis,
           dk.partei,
           (dm.anzahlstimmen - dk.anzahlstimmen)::decimal / (SELECT SUM(anzahlstimmen)
                                                             FROM direktkandidatur
                                                             WHERE wahlkreis = wk.wkid) AS rueckstand_prozent
    FROM wahlkreis wk,
         direktkandidatur dk,
         direktmandat dm
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
      AND wk.wkid = dk.wahlkreis
      AND wk.wkid = dm.wahlkreis
      AND dk.direktid != dm.direktid;

--Die 10 knappsten Wahlkreisniederlagen (falls keine Siege vorliegen)
CREATE MATERIALIZED VIEW kleinster_rueckstand_partei AS
    SELECT rd.partei, rd.wahlkreis, -rd.rueckstand_prozent AS vorsprung_prozent --unify schemas
    FROM rueckstand_direktmandat rd
    WHERE (SELECT COUNT(*)
           FROM rueckstand_direktmandat rd2
           WHERE rd.partei = rd2.partei
             AND rd2.rueckstand_prozent < rd.rueckstand_prozent) <= 9
      AND rd.partei NOT IN (SELECT partei FROM direktmandat); --party did not win any constituency

CREATE MATERIALIZED VIEW knappste_siege_oder_niederlagen AS
    SELECT *
    FROM kleinster_vorsprung_partei
    UNION
    SELECT *
    FROM kleinster_rueckstand_partei;

