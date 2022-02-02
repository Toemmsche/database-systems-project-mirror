DROP FUNCTION IF EXISTS zweitstimmen_aggriert CASCADE;

CREATE OR REPLACE FUNCTION zweitstimmen_aggregiert(
    wahl_input INTEGER, wk_nummern_input INTEGER ARRAY
)
    RETURNS TABLE
            (
                WAHL         INTEGER,
                PARTEI       VARCHAR(40),
                PARTEI_FARBE VARCHAR(6),
                ABS_STIMMEN  NUMERIC,
                REL_STIMMEN  NUMERIC
            )
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        WITH zweitstimmen_aggregiert(wahl, abs_stimmen) AS
                 (SELECT wk.wahl, SUM(ze.anzahlstimmen)
                  FROM wahlkreis wk,
                       zweitstimmenergebnis ze
                  WHERE wk.wkid = ze.wahlkreis
                    AND wk.nummer = ANY (wk_nummern_input)
                  GROUP BY wk.wahl),
             zweitstimmen_partei_aggregiert(wahl, partei, abs_stimmen) AS
                 (SELECT ll.wahl,
                         ll.partei,
                         SUM(ze.anzahlstimmen)
                  FROM wahlkreis wk,
                       landesliste ll,
                       zweitstimmenergebnis ze
                  WHERE wk.nummer = ANY (wk_nummern_input)
                    AND wk.wkid = ze.wahlkreis
                    AND ze.liste = ll.listenid
                  GROUP BY ll.wahl, ll.partei),
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
             zweitstimmen_qpartei_aggregiert(wahl, partei, partei_farbe, abs_stimmen, rel_stimmen) AS (
                 SELECT qp.wahl                                                 AS wahl,
                        p.kuerzel                                               AS partei,
                        p.farbe                                                 AS partei_farbe,
                        COALESCE(zpa.abs_stimmen, 0)                            AS abs_stimmen,
                        COALESCE(zpa.abs_stimmen, 0)::DECIMAL / zsa.abs_stimmen AS rel_stimmen
                 FROM partei p
                          LEFT OUTER JOIN zweitstimmen_partei_aggregiert zpa ON p.parteiid = zpa.partei,
                      qpartei qp,
                      zweitstimmen_aggregiert zsa
                 WHERE (zpa.wahl IS NULL OR zpa.wahl = qp.wahl) --zpa.wahl can be null because of left outer join
                   AND qp.wahl = zsa.wahl
                   AND p.parteiid = qp.partei
                 UNION
                 SELECT zpa.wahl                                        AS wahl,
                        'Sonstige'                                      AS partei,
                        'DDDDDD'                                        AS partei_farbe,
                        SUM(zpa.abs_stimmen)                            AS abs_stimmen,
                        SUM(zpa.abs_stimmen)::DECIMAL / zsa.abs_stimmen AS rel_stimmen
                 FROM zweitstimmen_partei_aggregiert zpa,
                      nicht_qpartei nqp,
                      zweitstimmen_aggregiert zsa
                 WHERE zpa.wahl = nqp.wahl
                   AND zpa.wahl = zsa.wahl
                   AND zpa.partei = nqp.partei
                 GROUP BY zpa.wahl, zsa.abs_stimmen)
        SELECT *
        FROM zweitstimmen_qpartei_aggregiert zpa
        WHERE zpa.wahl = wahl_input;
END;
$$

