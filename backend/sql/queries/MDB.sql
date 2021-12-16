DROP VIEW IF EXISTS mitglieder_bundestag CASCADE;

CREATE VIEW mitglieder_bundestag(wahl, vorname, nachname, partei, geburtsjahr, grund) AS
    SELECT m.wahl, k.vorname, k.nachname, p.kuerzel, k.geburtsjahr, m.grund
    FROM mandat m
             LEFT OUTER JOIN
         kandidat k ON m.kandidat = k.kandid,
         partei p
    WHERE m.partei = p.parteiid