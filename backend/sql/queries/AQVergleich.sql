DROP VIEW IF EXISTS zweitstimmen_qpartei_aq_hoch_vs_niedrig CASCADE;

CREATE VIEW zweitstimmen_qpartei_aq_hoch_vs_niedrig(typ, wahl, partei, partei_farbe, abs_stimmen) AS
    --Die zehn Wahlkreise (pro BTW) mit der höchsten Arbeitslosenquote und die zehn Wahlkreise (pro BTW) mit der höchsten Arbeitslosenquote
    WITH wahlkreis_aq(typ, wahlkreis) AS
             (SELECT 'niedrig', wk.wkid
              FROM (
                       SELECT wk.wkid,
                              ROW_NUMBER() OVER (PARTITION BY wk.wahl ORDER BY wk.arbeitslosenquote ASC) AS rang
                       FROM wahlkreis wk
                   ) AS wk
              WHERE wk.rang <= 10
              UNION
              SELECT 'hoch', wk.wkid
              FROM (
                       SELECT wk.wkid,
                              ROW_NUMBER() OVER (PARTITION BY wk.wahl ORDER BY wk.arbeitslosenquote DESC) AS rang
                       FROM wahlkreis wk
                   ) AS wk
              WHERE wk.rang <= 10),
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
         zweitstimmen_partei_wahlkreis(wahlkreis, partei, abs_stimmen) AS
             (SELECT wk.wkid,
                     ll.partei,
                     ze.anzahlstimmen
              FROM wahlkreis wk,
                   landesliste ll,
                   zweitstimmenergebnis ze
              WHERE wk.wkid = ze.wahlkreis
                AND ze.liste = ll.listenid)
    SELECT aq.typ, wk.wahl, p.kuerzel, p.farbe, SUM(zpw.abs_stimmen)
    FROM zweitstimmen_partei_wahlkreis zpw,
         wahlkreis_aq aq,
         wahlkreis wk,
         partei p,
         qpartei qp
    WHERE zpw.wahlkreis = aq.wahlkreis
      AND zpw.wahlkreis = wk.wkid
      AND zpw.partei = p.parteiid
      AND qp.partei = p.parteiid
    GROUP BY aq.typ, wk.wahl, p.kuerzel, p.farbe
    UNION
    SELECT aq.typ, wk.wahl, 'Sonstige', 'DDDDDD', SUM(zpw.abs_stimmen)
    FROM zweitstimmen_partei_wahlkreis zpw,
         wahlkreis_aq aq,
         wahlkreis wk,
         nicht_qpartei nqp
    WHERE zpw.wahlkreis = aq.wahlkreis
      AND zpw.wahlkreis = wk.wkid
      AND zpw.partei = nqp.partei
    GROUP BY aq.typ, wk.wahl;