DROP VIEW IF EXISTS wahlkreisinformation CASCADE;
DROP VIEW IF EXISTS erststimmen_qpartei_wahlkreis_rich CASCADE;
DROP VIEW IF EXISTS zweitstimmen_qpartei_wahlkreis_rich CASCADE;

CREATE VIEW wahlkreisinformation
            (wahl, land, wk_nummer, wk_name, sieger_vorname, sieger_nachname, sieger_partei, wahlbeteiligung_prozent) AS
    SELECT wk.wahl,
           bl.name,
           wk.nummer,
           wk.name,
           k.vorname                                          AS sieger_vorname,
           k.nachname                                         AS sieger_nachname,
           p.kuerzel                                          AS sieger_partei,
           SUM(ze.anzahlstimmen)::decimal * 100 / wk.deutsche AS wahlbeteiligung_prozent
    FROM wahlkreis wk,
         mandat m
             LEFT OUTER JOIN
         kandidat k ON k.kandid = m.kandidat,
         zweitstimmenergebnis ze,
         partei p,
         bundesland bl
    WHERE m.ist_direktmandat
      AND wk.wkid = m.wahlkreis
      AND wk.wkid = ze.wahlkreis
      AND m.partei = p.parteiid
      AND wk.land = bl.landid
    GROUP BY wk.wahl, bl.name, wk.nummer, wk.name, k.vorname, k.nachname, p.kuerzel, wk.deutsche;

CREATE VIEW stimmen_qpartei_wahlkreis_rich
            (stimmentyp, wahl, wk_nummer, partei, partei_farbe, abs_stimmen, rel_stimmen) AS
    WITH qpartei(wahl, partei) AS
             (SELECT DISTINCT m.wahl, m.partei
              FROM mandat m),
         nicht_qpartei(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
                  EXCEPT
              SELECT *
              FROM qpartei),
         erststimmen_wahlkreis(wahlkreis, anzahlstimmen) AS
             (SELECT dk.wahlkreis, SUM(dk.anzahlstimmen)
              FROM direktkandidatur dk
              GROUP BY dk.wahlkreis),
         erststimmen_partei_wahlkreis(wahlkreis, partei, abs_stimmen, rel_stimmen) AS
             (SELECT wk.wkid,
                     dk.partei,
                     dk.anzahlstimmen,
                     dk.anzahlstimmen::DECIMAL / ew.anzahlstimmen
              FROM wahlkreis wk,
                   direktkandidatur dk,
                   erststimmen_wahlkreis ew
              WHERE wk.wkid = ew.wahlkreis
                AND wk.wkid = dk.wahlkreis),
         zweitstimmen_wahlkreis(wahlkreis, anzahlstimmen) AS
             (SELECT ze.wahlkreis, SUM(ze.anzahlstimmen)
              FROM zweitstimmenergebnis ze
              GROUP BY ze.wahlkreis),
         zweitstimmen_partei_wahlkreis(wahlkreis, partei, abs_stimmen, rel_stimmen) AS
             (SELECT wk.wkid,
                     ll.partei,
                     ze.anzahlstimmen,
                     ze.anzahlstimmen::DECIMAL / zw.anzahlstimmen
              FROM wahlkreis wk,
                   landesliste ll,
                   zweitstimmenergebnis ze,
                   zweitstimmen_wahlkreis zw
              WHERE wk.wkid = zw.wahlkreis
                AND wk.wkid = ze.wahlkreis
                AND ze.liste = ll.listenid)
    SELECT 1,
           wk.wahl,
           wk.nummer,
           p.kuerzel,
           p.farbe,
           epw.abs_stimmen,
           epw.rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         partei p,
         qpartei qp,
         wahlkreis wk
    WHERE epw.partei = p.parteiid
      AND p.parteiid = qp.partei
      AND wk.wahl = qp.wahl
      AND epw.wahlkreis = wk.wkid
    UNION
    SELECT 1,
           wk.wahl,
           wk.nummer,
           'Sonstige',
           'DDDDDD',
           SUM(epw.abs_stimmen) AS abs_stimmen,
           SUM(epw.rel_stimmen) AS rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         wahlkreis wk,
         nicht_qpartei nqp
    WHERE epw.wahlkreis = wk.wkid
      AND epw.partei = nqp.partei
    GROUP BY wk.wahl, wk.nummer
    UNION
    SELECT 2,
           wk.wahl,
           wk.nummer,
           p.kuerzel AS partei,
           p.farbe   AS partei_farbe,
           zpw.abs_stimmen,
           zpw.rel_stimmen
    FROM zweitstimmen_partei_wahlkreis zpw,
         partei p,
         qpartei qp,
         wahlkreis wk
    WHERE zpw.partei = p.parteiid
      AND p.parteiid = qp.partei
      AND wk.wahl = qp.wahl
      AND zpw.wahlkreis = wk.wkid
      AND zpw.rel_stimmen >= 0.05
    UNION
    SELECT 2,
           wk.wahl,
           wk.nummer,
           'Sonstige',
           'DDDDDD',
           SUM(zpw.abs_stimmen) AS abs_stimmen,
           SUM(zpw.rel_stimmen) AS rel_stimmen
    FROM zweitstimmen_partei_wahlkreis zpw,
         wahlkreis wk,
         nicht_qpartei nqp
    WHERE zpw.wahlkreis = wk.wkid
      AND zpw.partei = nqp.partei
    GROUP BY wk.wahl, wk.nummer;