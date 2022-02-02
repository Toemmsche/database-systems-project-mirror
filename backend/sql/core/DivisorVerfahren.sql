DROP FUNCTION IF EXISTS divisorverfahren(integer, integer[]);

CREATE OR REPLACE FUNCTION divisorverfahren(summe_input INTEGER, werte INTEGER[])
    RETURNS NUMERIC
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    RETURN (WITH RECURSIVE
                data(wert) AS (
                    SELECT *
                    FROM UNNEST(werte)
                ),
                data_sum(wert_summe) AS (
                    SELECT SUM(d.wert)
                    FROM data d
                ),
                divisor_kandidat(divisor) AS (
                    VALUES ((0), (1))
                ),
                divisorverfahren
                    (summe, divisor, next_divisor) AS
                    (SELECT SUM(ROUND(d.wert / (ds.wert_summe::DECIMAL / summe_input))),
                            ds.wert_summe::DECIMAL / summe_input,
                            ds.wert_summe::DECIMAL / summe_input
                     FROM data d,
                          data_sum ds
                     GROUP BY ds.wert_summe, summe_input
                     UNION ALL
                     (
                         SELECT (SELECT SUM(ROUND(d.wert / dv.next_divisor))
                                 FROM data d),
                                dv.next_divisor,
                                CASE
                                    WHEN summe < summe_input THEN
                                        (SELECT AVG(d.divisor)
                                         FROM (SELECT d.wert /
                                                      (ROUND(d.wert / dv.next_divisor) + 0.5 + dk.divisor) AS divisor
                                               FROM data d,
                                                    divisor_kandidat dk
                                               ORDER BY divisor DESC
                                               LIMIT 2) AS d)
                                    WHEN summe > summe_input THEN
                                        (SELECT AVG(d.divisor)
                                         FROM (SELECT d.wert /
                                                      (ROUND(d.wert / dv.next_divisor) - 0.5 - dk.divisor) AS divisor
                                               FROM data d,
                                                    divisor_kandidat dk
                                               ORDER BY divisor
                                               LIMIT 2) AS d)
                                    ELSE dv.next_divisor
                                    END
                         FROM divisorverfahren dv
                         WHERE dv.summe != summe_input))
            SELECT dv.divisor
            FROM divisorverfahren dv
            WHERE dv.summe = summe_input);
END;
$$