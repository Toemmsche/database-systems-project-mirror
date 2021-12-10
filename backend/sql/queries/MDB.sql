DROP MATERIALIZED VIEW IF EXISTS mdb CASCADE;

CREATE MATERIALIZED VIEW mdb AS
    SELECT m.vorname, m.nachname, m.partei, k.geburtsjahr, m.grund
    FROM mandate m,
         kandidat k
    WHERE k.vorname = m.vorname
      AND k.nachname = m.nachname;