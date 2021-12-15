DROP MATERIALIZED VIEW IF EXISTS direktmandat CASCADE;
DROP MATERIALIZED VIEW IF EXISTS qpartei CASCADE;
DROP VIEW IF EXISTS zweitstimmen_qpartei_bundesland CASCADE;
DROP VIEW IF EXISTS zweitstimmen_qpartei CASCADE;

--Die Kandidaten bzw. die zugehörigen Parteien, die die Wahlkreise gewonnen haben
CREATE MATERIALIZED VIEW direktmandat(wahl, wahlkreis, land, kandidatur, partei, kandidaat) AS
    SELECT wk.wahl,
           wk.wkid,
           wk.land,
           dk.direktid,
           dk.partei,
           dk.kandidat
    FROM direktkandidatur dk,
         wahlkreis wk
    WHERE dk.wahlkreis = wk.wkid
      AND NOT EXISTS(SELECT *
                     FROM direktkandidatur dk2
                     WHERE dk2.wahlkreis = dk.wahlkreis
                       AND dk2.anzahlstimmen > dk.anzahlstimmen);


--Parteien, denen Sitze entsprechend ihres Zweitstimmenanteils zustehen
CREATE MATERIALIZED VIEW qpartei(wahl, partei) AS
    WITH zweitstimmen_partei(wahl, partei, anzahlstimmen) AS
             (SELECT zpb.wahl, zpb.partei, SUM(zpb.anzahlstimmen)
              FROM zweitstimmen_partei_bundesland zpb
              GROUP BY zpb.wahl, zpb.partei)
         --5% Hürde
    SELECT zp.wahl, zp.partei
    FROM zweitstimmen_partei zp
    WHERE zp.anzahlstimmen >=
          0.05 * (SELECT SUM(zp2.anzahlstimmen) FROM zweitstimmen_partei zp2 WHERE zp2.wahl = zp.wahl)
    UNION
    --3 Direktmandate
    SELECT dm.wahl, p.parteiid
    FROM partei p,
         direktmandat dm
    WHERE p.parteiid = dm.partei
    GROUP BY dm.wahl, p.parteiid
    HAVING COUNT(*) >= 3
    UNION
    --Nationale Minderheit
    SELECT btw.nummer, p.parteiid
    FROM bundestagswahl btw,
         partei p
    WHERE p.nationaleminderheit;


CREATE VIEW zweitstimmen_qpartei_bundesland(wahl, land, partei, anzahlstimmen) AS
    SELECT *
    FROM zweitstimmen_partei_bundesland zpb
    WHERE zpb.partei IN (SELECT p.partei FROM qpartei p WHERE zpb.wahl = p.wahl);


CREATE VIEW zweitstimmen_qpartei(wahl, partei, anzahlstimmen) AS
    SELECT zpb.wahl, zpb.partei, SUM(anzahlstimmen)
    FROM zweitstimmen_qpartei_bundesland zpb
    GROUP BY zpb.wahl, zpb.partei;