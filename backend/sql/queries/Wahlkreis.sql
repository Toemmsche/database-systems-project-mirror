DROP MATERIALIZED VIEW IF EXISTS wahlkreisinformation CASCADE;

CREATE MATERIALIZED VIEW wahlkreisinformation AS
    SELECT wk.nummer,
           wk.name,
           k.vorname as sieger_vorname,
           k.nachname as sieger_nachname,
           p.kuerzel as sieger_partei,
           SUM(ze.anzahlstimmen)::decimal / wk.deutsche AS wahlbeteiligung
    FROM wahlkreis wk,
         direktmandat dm,
         kandidat k,
         direktkandidatur dk,
         zweitstimmenergebnis ze,
         partei p
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
      AND dm.wahlkreis = wk.wkid
      AND k.kandid = dm.kandidat
      AND dm.direktid = dk.direktid
      AND dm.partei = p.parteiid
      AND ze.wahlkreis = wk.wkid
    GROUP BY wk.nummer, wk.name, k.vorname, k.nachname, p.kuerzel, wk.deutsche;


SELECT *
FROM wahlkreisinformation
where nummer = 199;