DROP VIEW IF EXISTS vorsprung_direktmandat_nummeriert CASCADE;
DROP VIEW IF EXISTS kleinster_vorsprung_partei CASCADE;
DROP VIEW IF EXISTS kleinster_rueckstand_partei_partei CASCADE;
DROP VIEW IF EXISTS kleinste_siege_oder_niederlagen CASCADE;

--Absoluter Unterschied in Erststimmenanteil zwischen Wahlkreissieger und den verlierern
CREATE VIEW vorsprung_direktmandat_nummeriert
            (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
             wk_rang)
AS
    WITH direktmandat_stimmen AS
             (SELECT dm.*, dk.anzahlstimmen
              FROM direktmandat dm,
                   direktkandidatur dk
              WHERE dm.kandidatur = dk.direktid),
         direktkandidatur_nummeriert(wahlkreis, kandidatur, partei, anzahlstimmen, wk_rang) AS
             (SELECT dk.wahlkreis,
                     dk.direktid,
                     dk.partei,
                     dk.anzahlstimmen,
                     ROW_NUMBER() OVER (PARTITION BY dk.wahlkreis ORDER BY dk.anzahlstimmen DESC)
              FROM direktkandidatur dk)
    SELECT wk.wahl,
           dm.kandidatur,
           dm.partei,
           dkn.kandidatur,
           dkn.partei,
           dm.anzahlstimmen - dkn.anzahlstimmen,
           dkn.wk_rang
    FROM direktkandidatur_nummeriert dkn,
         direktmandat_stimmen dm,
         wahlkreis wk
    WHERE wk.wkid = dm.wahlkreis
      AND dm.wahlkreis = dkn.wahlkreis
      AND dm.partei != dkn.partei;

--Die 10 knappsten Wahlkreissiege (falls vorhanden)
CREATE VIEW kleinster_vorsprung_partei
            (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
             wk_rang, knappheit_rang)
AS
    WITH siege_nummeriert AS
             (SELECT vdn.*,
                     ROW_NUMBER()
                     OVER (PARTITION BY vdn.wahl, vdn.sieger_partei ORDER BY vdn.differenz_stimmen ASC) AS knappheit_rang
              FROM vorsprung_direktmandat_nummeriert vdn
              WHERE vdn.wk_rang = 2)
    SELECT *
    FROM siege_nummeriert sn
    WHERE sn.knappheit_rang <= 10;

--Die 10 knappsten Wahlkreisniederlagen (falls keine Siege vorliegen)
CREATE VIEW kleinster_rueckstand_partei
            (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
             wk_rang, knappheit_rang)
AS
    WITH niederlagen_nummeriert AS
             (SELECT vdn.*,
                     ROW_NUMBER()
                     OVER (PARTITION BY vdn.wahl, vdn.verlierer_partei ORDER BY vdn.differenz_stimmen ASC) AS knappheit_rang
              FROM vorsprung_direktmandat_nummeriert vdn)
    SELECT *
    FROM niederlagen_nummeriert sn
    WHERE sn.knappheit_rang <= 10;


CREATE VIEW knappste_siege_oder_niederlagen
            (is_sieg, wahl, wk_nummer, wk_name, sieger_partei, verlierer_partei, differenz_stimmen) AS
    WITH partei_ohne_direktmandat(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
              EXCEPT
              SELECT distinct dm.wahl, dm.partei
              FROM direktmandat dm)
    SELECT TRUE, kvp.wahl, wk.nummer, wk.name, sp.kuerzel, vp.kuerzel, kvp.differenz_stimmen
    FROM kleinster_vorsprung_partei kvp,
         partei sp,
         partei vp,
         direktkandidatur dk,
         wahlkreis wk
    WHERE kvp.sieger_partei = sp.parteiid
      AND kvp.verlierer_partei = vp.parteiid
      AND kvp.sieger_kandidatur = dk.direktid
      AND dk.wahlkreis = wk.wkid
    UNION
    SELECT FALSE, krp.wahl, wk.nummer, wk.name, sp.kuerzel, vp.kuerzel, krp.differenz_stimmen
    FROM kleinster_rueckstand_partei krp,
         partei sp,
         partei_ohne_direktmandat pod,
         partei vp,
         direktkandidatur dk,
         wahlkreis wk
    WHERE krp.sieger_partei = sp.parteiid
      AND krp.verlierer_partei = pod.partei
      AND pod.partei = vp.parteiid
      AND krp.sieger_kandidatur = dk.direktid
      AND dk.wahlkreis = wk.wkid;

        