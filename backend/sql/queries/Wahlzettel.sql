DROP VIEW IF EXISTS stimmzettel_2021 CASCADE;

CREATE VIEW stimmzettel_2021 (wahl, land, wk_nummer, wk_name, position, dk_vorname, dk_nachname, partei, partei_farbe) AS
    (
    SELECT wk.wahl,
           bl.name,
           wk.nummer,
           wk.name,
           ll.stimmzettelposition,
           k.vorname,
           k.nachname,
           p.kuerzel,
           p.farbe
    FROM wahlkreis wk,
         direktkandidatur dk
             LEFT OUTER JOIN kandidat k ON dk.kandidat = k.kandid,
         landesliste ll,
         bundesland bl,
         partei p
    WHERE wk.wahl = 20
      AND ll.wahl = wk.wahl
      AND wk.wkid = dk.wahlkreis
      AND wk.land = ll.land
      AND wk.land = bl.landid
      AND dk.partei = p.parteiid
      AND dk.partei = ll.partei
    UNION
    SELECT ll.wahl,
           bl.name,
           wk.nummer,
           wk.name,
           ll.stimmzettelposition,
           NULL,
           NULL,
           p.kuerzel,
           p.farbe
    FROM wahlkreis wk,
         landesliste ll,
         bundesland bl,
         partei p
    WHERE wk.wahl = 20
      AND ll.wahl = wk.wahl
      AND wk.land = ll.land
      AND wk.land = bl.landid
      AND ll.partei = p.parteiid
      AND NOT EXISTS(SELECT *
                     FROM direktkandidatur dk
                     WHERE dk.wahlkreis = wk.wkid
                       AND dk.partei = ll.partei)
        )
    ORDER BY nummer, stimmzettelposition;