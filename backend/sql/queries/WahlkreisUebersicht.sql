DROP VIEW IF EXISTS wahlkreisinformation CASCADE;
DROP VIEW IF EXISTS erststimmen_qpartei_wahlkreis_rich CASCADE;

CREATE VIEW wahlkreisinformation
            (wahl, wahlkreis, name, sieger_vorname, sieger_nachname, sieger_partei, wahlbeteiligung_prozent) AS
    SELECT wk.wahl,
           wk.nummer,
           wk.name,
           k.vorname                                          AS sieger_vorname,
           k.nachname                                         AS sieger_nachname,
           p.kuerzel                                          AS sieger_partei,
           SUM(ze.anzahlstimmen)::decimal * 100 / wk.deutsche AS wahlbeteiligung_prozent
    FROM wahlkreis wk,
         direktmandat dm
             LEFT OUTER JOIN
         kandidat k ON k.kandid = dm.kandidat,
         zweitstimmenergebnis ze,
         partei p
    WHERE dm.wahlkreis = wk.wkid
      AND dm.partei = p.parteiid
      AND ze.wahlkreis = wk.wkid
    GROUP BY wk.wahl, wk.nummer, wk.name, k.vorname, k.nachname, p.kuerzel, wk.deutsche;

CREATE VIEW erststimmen_qpartei_wahlkreis_rich(wahl, wahlkreis, partei, partei_farbe, abs_stimmen, rel_stimmen) AS
    WITH erststimmen_wahlkreis(wahl, wahlkreis, anzahlstimmen) AS
             (SELECT wk.wahl, wk.wkid, SUM(anzahlstimmen)
              FROM wahlkreis wk,
                   direktkandidatur dk
              WHERE dk.wahlkreis = wk.wkid
              GROUP BY wk.wahl, wk.wkid),
         erststimmen_partei_wahlkreis(wahl, wahlkreis, partei, abs_stimmen, rel_stimmen) AS
             (SELECT wk.wahl,
                     wk.wkid,
                     dk.partei,
                     dk.anzahlstimmen,
                     dk.anzahlstimmen::DECIMAL / ew.anzahlstimmen
              FROM wahlkreis wk,
                   direktkandidatur dk,
                   erststimmen_wahlkreis ew
              WHERE wk.wahl = ew.wahl
                AND wk.wkid = ew.wahlkreis
                AND wk.wkid = dk.wahlkreis),
         nicht_qpartei(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM partei p,
                   bundestagswahl btw
              EXCEPT
              SELECT *
              FROM qpartei)
    SELECT wk.wahl, wk.nummer, p.kuerzel AS partei, p.farbe AS partei_farbe, epw.abs_stimmen, epw.rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         qpartei qp,
         partei p,
         wahlkreis wk
    WHERE wk.wahl = epw.wahl
      AND wk.wahl = qp.wahl
      AND qp.partei = p.parteiid
      AND epw.partei = p.parteiid
      AND epw.wahlkreis = wk.wkid
    UNION
    SELECT wk.wahl,
           wk.nummer,
           'Sonstige',
           'DDDDDD',
           SUM(epw.abs_stimmen) AS abs_stimmen,
           SUM(epw.rel_stimmen) AS rel_stimmen
    FROM erststimmen_partei_wahlkreis epw,
         nicht_qpartei np,
         wahlkreis wk
    WHERE wk.wahl = epw.wahl
      AND epw.partei = np.partei
      AND epw.wahlkreis = wk.wkid
    GROUP BY wk.wahl, wk.nummer;

