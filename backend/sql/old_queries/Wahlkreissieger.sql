DROP MATERIALIZED VIEW IF EXISTS wahlkreissieger_zweitstimme CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wahlkreissieger_erststimme CASCADE;

CREATE MATERIALIZED VIEW wahlkreissieger_zweitstimme AS
    SELECT wk.nummer, wk.name, p.kuerzel AS partei, p.farbe AS partei_farbe
    FROM zweitstimmenergebnis ze,
         landesliste ll,
         partei p,
         wahlkreis wk
    WHERE wk.wahl = (SELECT * FROM wahlauswahl)
      AND wk.wkid = ze.wahlkreis
      AND ll.listenid = ze.liste
      AND ll.partei = p.parteiid
      AND ze.anzahlstimmen = (SELECT MAX(ze2.anzahlstimmen)
                              FROM zweitstimmenergebnis ze2
                              WHERE ze2.wahlkreis = ze.wahlkreis);

CREATE MATERIALIZED VIEW wahlkreissieger_erststimme AS
    SELECT wk.nummer, wk.name, p.kuerzel AS partei, p.farbe AS partei_farbe
    FROM wahlkreis wk,
         direktmandat dm,
         partei p
    WHERE wk.wkid = dm.wahlkreis
      AND dm.partei = p.parteiid;


CREATE MATERIALIZED VIEW wahlkreissieger AS
    SELECT we.nummer,
           we.name,
           we.partei       AS erststimme_sieger,
           we.partei_farbe AS erststimme_sieger_farbe,
           wz.partei       AS zweitstimme_sieger,
           wz.partei_farbe AS zweitstimme_sieger_farbe
    FROM wahlkreissieger_erststimme we,
         wahlkreissieger_zweitstimme wz
    WHERE we.nummer = wz.nummer;
