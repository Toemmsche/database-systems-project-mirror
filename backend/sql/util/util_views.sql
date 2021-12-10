DROP MATERIALIZED VIEW IF EXISTS erststimmen_qpartei_wahlkreis CASCADE;

CREATE MATERIALIZED VIEW erststimmen_qpartei_wahlkreis AS
    SELECT wk.nummer,
           p.kuerzel                                                                               AS partei,
           dk.anzahlstimmen                                                                        AS abs_stimmen,
           dk.anzahlstimmen::decimal /
           (SELECT SUM(dk2.anzahlstimmen) FROM direktkandidatur dk2 WHERE dk2.wahlkreis = wk.wkid) AS rel_stimmen
    FROM qpartei qp,
         direktkandidatur dk,
         wahlkreis wk,
         partei p
    WHERE qp.partei = dk.partei
      AND qp.partei = p.parteiid
      AND dk.wahlkreis = wk.wkid
      AND wk.wahl = (SELECT * FROM wahlauswahl);


select * from erststimmen_qpartei_wahlkreis;
