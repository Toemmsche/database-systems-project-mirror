DROP VIEW IF EXISTS knappste_siege_oder_niederlagen CASCADE;

CREATE VIEW knappste_siege_oder_niederlagen
            (is_sieg, wahl, wk_nummer, wk_name, sieger_partei, verlierer_partei, abs_stimmen_sieger, abs_stimmen_verlierer, differenz_stimmen) AS
    WITH direktkandidatur_nummeriert(partei, wahlkreis, kandidatur, anzahlstimmen, wk_rang) AS
             (SELECT dk.partei,
                     dk.wahlkreis,
                     dk.direktid,
                     dk.anzahlstimmen,
                     ROW_NUMBER() OVER (PARTITION BY dk.wahlkreis ORDER BY dk.anzahlstimmen DESC)
              FROM direktkandidatur dk),
         direktmandat_stimmen(wahl, partei, wahlkreis, kandidatur, anzahlstimmen) AS
             (SELECT wk.wahl,
                     dkn.partei,
                     wk.wkid,
                     dkn.kandidatur,
                     dkn.anzahlstimmen
              FROM direktkandidatur_nummeriert dkn,
                   wahlkreis wk
              WHERE dkn.wahlkreis = wk.wkid
                AND dkn.wk_rang = 1),
         vorsprung_direktmandat_nummeriert
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, abs_stimmen_sieger, abs_stimmen_verlierer, differenz_stimmen,
              wk_rang)
             AS
             (SELECT dm.wahl,
                     dm.kandidatur,
                     dm.partei,
                     dkn.kandidatur,
                     dkn.partei,
                     dm.anzahlstimmen AS abs_stimmen_sieger,
                     dkn.anzahlstimmen AS abs_stimmen_verlierer,
                     dm.anzahlstimmen - dkn.anzahlstimmen,
                     dkn.wk_rang
              FROM direktkandidatur_nummeriert dkn,
                   direktmandat_stimmen dm
              WHERE dm.wahlkreis = dkn.wahlkreis
                AND dm.partei != dkn.partei),
         siege_nummeriert AS
             (SELECT vdn.*,
                     ROW_NUMBER()
                     OVER (PARTITION BY vdn.wahl, vdn.sieger_partei ORDER BY vdn.differenz_stimmen ASC) AS knappheit_rang
              FROM vorsprung_direktmandat_nummeriert vdn
              WHERE vdn.wk_rang = 2),
         kleinster_vorsprung_partei
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, abs_stimmen_sieger, abs_stimmen_verlierer, differenz_stimmen,
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
             (wahl, sieger_kandidatur, sieger_partei, verlierer_kandidatur, verlierer_partei, abs_stimmen_sieger, abs_stimmen_verlierer, differenz_stimmen,
              wk_rang, knappheit_rang)
             AS
             (SELECT *
              FROM niederlagen_nummeriert sn
              WHERE sn.knappheit_rang <= 10),
         partei_ohne_direktmandat(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
              WHERE NOT p.ist_einzelbewerbung --Einzelbewerbungen "verschmutzen" die Statistik
              EXCEPT
              SELECT DISTINCT dm.wahl, dm.partei
              FROM direktmandat_stimmen dm)
    SELECT TRUE, kvp.wahl, wk.nummer, wk.name, sp.kuerzel, vp.kuerzel, kvp.abs_stimmen_sieger, kvp.abs_stimmen_verlierer, kvp.differenz_stimmen
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
    SELECT FALSE, krp.wahl, wk.nummer, wk.name, sp.kuerzel, vp.kuerzel, krp.abs_stimmen_sieger, krp.abs_stimmen_verlierer, krp.differenz_stimmen
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

        