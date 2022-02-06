DROP FUNCTION IF EXISTS landesliste_kandidaten CASCADE;

CREATE FUNCTION landesliste_kandidaten(wahlkreis INT, wahl INT)
    RETURNS TABLE(platz INT, vorname TEXT, nachname TEXT, partei TEXT, partei_farbe TEXT)
AS $$ SELECT lp.position,
             k.vorname,
             k.nachname,
             p.kuerzel,
             p.farbe
      FROM listenplatz lp
                LEFT OUTER JOIN kandidat k ON lp.kandidat = k.kandid,
           landesliste ll,
           partei p,
           wahlkreis wk
      WHERE lp.liste = ll.listenid
        AND ll.partei = p.parteiid
        AND wk.land = ll.land
        AND wk.nummer = $1
        AND wk.wahl = $2
$$ LANGUAGE SQL;