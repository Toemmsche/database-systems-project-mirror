DROP MATERIALIZED VIEW IF EXISTS erststimmen_partei_wahlkreis CASCADE;
DROP MATERIALIZED VIEW IF EXISTS erststimmen_qpartei_wahlkreis CASCADE;

CREATE MATERIALIZED VIEW erststimmen_partei_wahlkreis AS
    SELECT wk.wkid                                                                                 AS wahlkreis,
           p.parteiid                                                                              AS partei,
           dk.anzahlstimmen                                                                        AS abs_stimmen,
           dk.anzahlstimmen::decimal /
           (SELECT SUM(dk2.anzahlstimmen) FROM direktkandidatur dk2 WHERE dk2.wahlkreis = wk.wkid) AS rel_stimmen
    FROM direktkandidatur dk,
         wahlkreis wk,
         partei p
    WHERE p.parteiid = dk.partei
      AND dk.wahlkreis = wk.wkid
      AND wk.wahl = (SELECT * FROM wahlauswahl);

CREATE MATERIALIZED VIEW erststimmen_qpartei_wahlkreis AS
    SELECT *
    FROM erststimmen_partei_wahlkreis ew
    WHERE ew.partei IN (SELECT * FROM qpartei)
