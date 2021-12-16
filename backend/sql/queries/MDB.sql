DROP VIEW IF EXISTS mitglieder_bundestag CASCADE;

CREATE VIEW mitglieder_bundestag AS
    SELECT m.wahl, k.vorname, k.nachname, m.partei, k.geburtsjahr, m.grund
    FROM mandat m
             LEFT OUTER JOIN
         kandidat k ON m.kandidat = k.kandid