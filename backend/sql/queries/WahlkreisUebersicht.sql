DROP VIEW IF EXISTS wahlkreisinformation CASCADE;
DROP VIEW IF EXISTS stimmen_qpartei_wahlkreis_rich CASCADE;

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
    WITH erststimmen_wahlkreis(wahlkreis, abs_stimmen) AS
             (SELECT dk.wahlkreis,
                     SUM(dk.anzahlstimmen) AS abs_stimmen
              FROM direktkandidatur dk
              GROUP BY dk.wahlkreis),
         zweitstimmen_wahlkreis(wahlkreis, abs_stimmen) AS
             (SELECT ze.wahlkreis,
                     SUM(ze.anzahlstimmen) AS abs_stimmen
              FROM zweitstimmenergebnis ze
              GROUP BY ze.wahlkreis),
         qpartei(wahl, partei) AS
             (SELECT DISTINCT m.wahl, m.partei
              FROM mandat m),
         nicht_qpartei(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM bundestagswahl btw,
                   partei p
                  EXCEPT
              SELECT *
              FROM qpartei),
         erststimmen_partei_wahlkreis(wahlkreis, partei, abs_stimmen) AS
             (SELECT wk.wkid,
                     dk.partei,
                     dk.anzahlstimmen
              FROM wahlkreis wk,
                   direktkandidatur dk
              WHERE wk.wkid = dk.wahlkreis),
         zweitstimmen_partei_wahlkreis(wahlkreis, partei, abs_stimmen) AS
             (SELECT wk.wkid,
                     ll.partei,
                     ze.anzahlstimmen
              FROM wahlkreis wk,
                   landesliste ll,
                   zweitstimmenergebnis ze
              WHERE wk.wkid = ze.wahlkreis
                AND ze.liste = ll.listenid)
    SELECT 1,
           wk.wahl,
           wk.nummer,
           p.kuerzel,
           p.farbe,
           epw.abs_stimmen,
           epw.abs_stimmen::decimal / ewk.abs_stimmen AS rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         partei p,
         qpartei qp,
         wahlkreis wk,
         erststimmen_wahlkreis ewk
    WHERE epw.partei = p.parteiid
      AND p.parteiid = qp.partei
      AND wk.wahl = qp.wahl
      AND epw.wahlkreis = wk.wkid
      AND epw.wahlkreis = ewk.wahlkreis
    UNION
    SELECT 1,
           wk.wahl,
           wk.nummer,
           'Sonstige',
           'DDDDDD',
           SUM(epw.abs_stimmen) AS abs_stimmen,
           SUM(epw.abs_stimmen)::decimal / ewk.abs_stimmen AS rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         wahlkreis wk,
         nicht_qpartei nqp,
         erststimmen_wahlkreis ewk
    WHERE epw.wahlkreis = wk.wkid
      AND epw.partei = nqp.partei
      AND epw.wahlkreis = ewk.wahlkreis
    GROUP BY wk.wahl, wk.nummer, ewk.abs_stimmen
    UNION
    SELECT 2,
           wk.wahl,
           wk.nummer,
           p.kuerzel AS partei,
           p.farbe   AS partei_farbe,
           zpw.abs_stimmen,
           zpw.abs_stimmen::decimal / zwk.abs_stimmen AS rel_stimmen
    FROM zweitstimmen_partei_wahlkreis zpw,
         partei p,
         qpartei qp,
         wahlkreis wk,
         zweitstimmen_wahlkreis zwk
    WHERE zpw.partei = p.parteiid
      AND p.parteiid = qp.partei
      AND wk.wahl = qp.wahl
      AND zpw.wahlkreis = wk.wkid
      AND zpw.wahlkreis = zwk.wahlkreis
    UNION
    SELECT 2,
           wk.wahl,
           wk.nummer,
           'Sonstige',
           'DDDDDD',
           SUM(zpw.abs_stimmen) AS abs_stimmen,
           SUM(zpw.abs_stimmen)::decimal / zwk.abs_stimmen AS rel_stimmen
    FROM zweitstimmen_partei_wahlkreis zpw,
         wahlkreis wk,
         nicht_qpartei nqp,
         zweitstimmen_wahlkreis zwk
    WHERE zpw.wahlkreis = wk.wkid
      AND zpw.partei = nqp.partei
      AND zpw.wahlkreis = zwk.wahlkreis
    GROUP BY wk.wahl, wk.nummer, zwk.abs_stimmen;