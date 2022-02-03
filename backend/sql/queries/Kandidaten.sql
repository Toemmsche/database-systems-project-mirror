DROP VIEW IF EXISTS kandidaten_erweitert CASCADE;

CREATE VIEW kandidaten_erweitert
            (wahl, ist_einzug, ist_direktmandat, titel, nachname, vorname, geburtsjahr, geschlecht, beruf,
             ist_einzelbewerbung, partei, partei_lang,
             partei_farbe, bundesland, listenplatz, wk_nummer, wk_name, rel_stimmen)
AS
    WITH erststimmen_wahlkreis(wahlkreis, abs_stimmen) AS
             (SELECT dk.wahlkreis,
                     SUM(dk.anzahlstimmen) AS abs_stimmen
              FROM direktkandidatur dk
              GROUP BY dk.wahlkreis),
         direktkandidatur_relativ(kandidatur, rel_stimmen) AS (
             SELECT dk.direktid,
                    dk.anzahlstimmen::Decimal / ew.abs_stimmen
             FROM direktkandidatur dk,
                  erststimmen_wahlkreis ew
             WHERE dk.wahlkreis = ew.wahlkreis
         )
    SELECT DISTINCT COALESCE(wk.wahl, ll.wahl),
                    m.kandidat IS NOT NULL,
                    m.ist_direktmandat,
                    k.titel,
                    k.nachname,
                    k.vorname,
                    k.geburtsjahr,
                    k.geschlecht,
                    k.beruf,
                    COALESCE(llp.ist_einzelbewerbung, dkp.ist_einzelbewerbung),
                    COALESCE(llp.kuerzel, dkp.kuerzel),
                    COALESCE(llp.name, dkp.name),
                    COALESCE(llp.farbe, dkp.farbe),
                    bl.name,
                    lp.position,
                    wk.nummer,
                    wk.name,
                    dr.rel_stimmen
    FROM kandidat k --all candidates
             LEFT OUTER JOIN mandat m ON m.kandidat = k.kandid
             LEFT OUTER JOIN listenplatz lp ON lp.kandidat = k.kandid
             LEFT OUTER JOIN landesliste ll ON ll.listenid = lp.liste
             LEFT OUTER JOIN bundesland bl ON bl.landid = ll.land
             LEFT OUTER JOIN direktkandidatur dk ON dk.kandidat = k.kandid
             LEFT OUTER JOIN direktkandidatur_relativ dr ON dr.kandidatur = dk.direktid
             LEFT OUTER JOIN wahlkreis wk ON dk.wahlkreis = wk.wkid
             LEFT OUTER JOIN partei llp ON llp.parteiid = ll.partei
             LEFT OUTER JOIN partei dkp ON dkp.parteiid = dk.partei;