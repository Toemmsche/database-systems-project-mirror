DROP VIEW IF EXISTS knappste_siege_oder_niederlagen CASCADE;

CREATE VIEW knappste_siege_oder_niederlagen
            (is_sieg, wahl, wk_nummer, wk_name, sieger_partei, verlierer_partei, differenz_stimmen) AS
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
              FROM direktkandidatur dk),
         vorsprung_direktmandat_nummeriert
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
              wk_rang)
             AS
             (SELECT wk.wahl,
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
                AND dm.partei != dkn.partei),
         siege_nummeriert AS
             (SELECT vdn.*,
                     ROW_NUMBER()
                     OVER (PARTITION BY vdn.wahl, vdn.sieger_partei ORDER BY vdn.differenz_stimmen ASC) AS knappheit_rang
              FROM vorsprung_direktmandat_nummeriert vdn
              WHERE vdn.wk_rang = 2),
         kleinster_vorsprung_partei
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
              wk_rang, knappheit_rang)
             AS
             (SELECT *
              FROM siege_nummeriert sn
              WHERE sn.knappheit_rang <= 10),
         niederlagen_nummeriert AS
             (SELECT vdn.*,
                     ROW_NUMBER()
                     OVER (PARTITION BY vdn.wahl, vdn.verlierer_partei ORDER BY vdn.differenz_stimmen ASC) AS knappheit_rang
              FROM vorsprung_direktmandat_nummeriert vdn),
         kleinster_rueckstand_partei
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, differenz_stimmen,
              wk_rang, knappheit_rang)
             AS
             (SELECT *
              FROM niederlagen_nummeriert sn
              WHERE sn.knappheit_rang <= 10),
         partei_ohne_direktmandat(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
              EXCEPT
              SELECT DISTINCT dm.wahl, dm.partei
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

        