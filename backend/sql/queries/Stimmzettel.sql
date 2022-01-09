DROP VIEW IF EXISTS stimmzettel_2021 CASCADE;

CREATE VIEW stimmzettel_2021 (wk_nummer, position, kandidatur, dk_vorname, dk_nachname, liste, partei, partei_farbe) AS
    (
    SELECT wk.nummer,
           ll.stimmzettelposition,
           dk.direktid,
           k.vorname,
           k.nachname,
           ll.listenid,
           p.kuerzel,
           p.farbe
    FROM wahlkreis wk,
         direktkandidatur dk
             LEFT OUTER JOIN kandidat k ON dk.kandidat = k.kandid,
         landesliste ll,
         partei p
    WHERE wk.wahl = 20
      AND ll.wahl = wk.wahl
      AND wk.wkid = dk.wahlkreis
      AND wk.land = ll.land
      AND dk.partei = p.parteiid
      AND dk.partei = ll.partei
    UNION
    SELECT wk.nummer,
           ll.stimmzettelposition,
           NULL,
           NULL,
           NULL,
           ll.listenid,
           p.kuerzel,
           p.farbe
    FROM wahlkreis wk,
         landesliste ll,
         bundesland bl,
         partei p
    WHERE wk.wahl = 20
      AND ll.wahl = wk.wahl
      AND wk.land = ll.land
      AND ll.partei = p.parteiid
      AND NOT EXISTS(SELECT *
                     FROM direktkandidatur dk
                     WHERE dk.wahlkreis = wk.wkid
                       AND dk.partei = ll.partei)
        )
    ORDER BY nummer, stimmzettelposition;