DROP VIEW IF EXISTS mitglieder_bundestag CASCADE;

CREATE VIEW mitglieder_bundestag(wahl, vorname, nachname, partei, geburtsjahr, grund) AS
    SELECT m.wahl,
           k.vorname,
           k.nachname,
           p.kuerzel,
           k.geburtsjahr,
           'Direktmandat aus Wahlkreis ' || wk.nummer || ' - ' || wk.name
    FROM mandat m
             LEFT OUTER JOIN kandidat k ON m.kandidat = k.kandid,
         partei p,
         wahlkreis wk,
         bundesland bl
    WHERE m.wahlkreis = wk.wkid
      AND m.land = bl.landid
      AND m.partei = p.parteiid
      AND m.ist_direktmandat
    UNION
    SELECT m.wahl,
           k.vorname,
           k.nachname,
           p.kuerzel,
           k.geburtsjahr,
           'Landeslistenmandat von Listenplatz ' || m.position || ' in ' || bl.name
    FROM mandat m
             LEFT OUTER JOIN kandidat k ON m.kandidat = k.kandid,
         partei p,
         bundesland bl
    WHERE m.land = bl.landid
      AND m.partei = p.parteiid
      AND NOT m.ist_direktmandat