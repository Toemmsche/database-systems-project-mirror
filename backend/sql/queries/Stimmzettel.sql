DROP VIEW IF EXISTS stimmzettel_2021 CASCADE;

CREATE VIEW stimmzettel_2021 (wk_nummer, position, ist_einzelbewerbung, kandidatur, dk_vorname, dk_nachname, liste, partei, partei_lang, partei_farbe) AS
    SELECT wk.nummer,
           ll.stimmzettelposition,
           p.ist_einzelbewerbung,
           dk.direktid,
           k.vorname,
           k.nachname,
           ll.listenid,
           p.kuerzel,
           p.name,
           p.farbe
    FROM wahlkreis wk
             INNER JOIN landesliste ll ON wk.land = ll.land AND wk.wahl = ll.wahl
             LEFT OUTER JOIN direktkandidatur dk ON dk.wahlkreis = wk.wkid AND dk.partei = ll.partei
             LEFT OUTER JOIN kandidat k ON dk.kandidat = k.kandid,
         partei p
    WHERE wk.wahl = 20
      AND ll.partei = p.parteiid
      AND NOT p.ist_einzelbewerbung
    UNION
    SELECT wk.nummer,
           1000000, --arbitrarily large value
           p.ist_einzelbewerbung,
           dk.direktid,
           k.vorname,
           k.nachname,
           NULL,
           p.kuerzel,
           p.name,
           p.farbe
    FROM wahlkreis wk,
         direktkandidatur dk,
         kandidat k,
         partei p
    WHERE wk.wahl = 20
      AND wk.wkid = dk.wahlkreis
      AND dk.kandidat = k.kandid
      AND dk.partei = p.parteiid
      AND p.ist_einzelbewerbung
    ORDER BY nummer, stimmzettelposition;