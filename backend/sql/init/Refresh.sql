UPDATE zweitstimmenergebnis
SET anzahlstimmen = anzahlstimmen + 10000
WHERE wahlkreis % 100 = 17;


REFRESH MATERIALIZED VIEW zweitstimmen_partei_wahlkreis;
REFRESH MATERIALIZED VIEW zweitstimmen_partei_bundesland;
REFRESH MATERIALIZED VIEW zweitstimmen_partei;
REFRESH MATERIALIZED VIEW direktmandat;
REFRESH MATERIALIZED VIEW qpartei;
REFRESH MATERIALIZED VIEW sitze_bundesland;
REFRESH MATERIALIZED VIEW mindestsitze_qpartei_bundesland;
REFRESH MATERIALIZED VIEW sitze_nach_erhoehung;

SELECT *
FROM sitze_nach_erhoehung;