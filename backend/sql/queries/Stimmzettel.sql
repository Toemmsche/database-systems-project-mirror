DROP VIEW IF EXISTS stimmzettel_2021 CASCADE;

CREATE VIEW stimmzettel_2021
            (wk_nummer, position, hat_landesliste, kandidatur, dk_vorname, dk_nachname, liste, partei, partei_lang, partei_farbe) AS
    WITH eintraege(land, wk_nummer, hat_landesliste, kandidatur, dk_vorname, dk_nachname, liste, partei) AS
             (SELECT wk.land,
                     wk.nummer,
                     TRUE,
                     dk.direktid,
                     k.vorname,
                     k.nachname,
                     ll.listenid,
                     ll.partei
              FROM wahlkreis wk
                       INNER JOIN landesliste ll ON wk.land = ll.land AND wk.wahl = ll.wahl
                       LEFT OUTER JOIN direktkandidatur dk ON dk.wahlkreis = wk.wkid AND dk.partei = ll.partei
                       LEFT OUTER JOIN kandidat k ON dk.kandidat = k.kandid
              WHERE wk.wahl = 20
              UNION
              SELECT wk.land,
                     wk.nummer,
                     FALSE,
                     dk.direktid,
                     k.vorname,
                     k.nachname,
                     NULL,
                     dk.partei
              FROM wahlkreis wk,
                   direktkandidatur dk,
                   kandidat k
              WHERE wk.wahl = 20
                AND wk.wkid = dk.wahlkreis
                AND dk.kandidat = k.kandid
                AND NOT EXISTS(SELECT * FROM landesliste ll WHERE ll.land = wk.land AND ll.partei = dk.partei and wk.wahl = ll.wahl))
    SELECT e.wk_nummer,
           COALESCE(prf.position, 100000), --arbitrarily large number
           e.hat_landesliste,
           e.kandidatur,
           e.dk_vorname,
           e.dk_nachname,
           e.liste,
           p.kuerzel,
           p.name,
           p.farbe
    FROM eintraege e
             LEFT OUTER JOIN parteireihenfolge prf ON prf.partei = e.partei
        AND prf.land = e.land
        AND prf.wahl = 20,
         partei p
    WHERE e.partei = p.parteiid
    ORDER BY e.wk_nummer, prf.position;