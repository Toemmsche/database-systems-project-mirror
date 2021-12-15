REFRESH MATERIALIZED VIEW zweitstimmen_partei_wahlkreis;
REFRESH MATERIALIZED VIEW zweitstimmen_partei_bundesland;
REFRESH MATERIALIZED VIEW zweitstimmen_partei;
REFRESH MATERIALIZED VIEW direktmandat;
REFRESH MATERIALIZED VIEW qpartei;
REFRESH MATERIALIZED VIEW zweitstimmen_qpartei_bundesland;
REFRESH MATERIALIZED VIEW direktmandate_qpartei_bundesland;
REFRESH MATERIALIZED VIEW sitze_bundesland;
REFRESH MATERIALIZED VIEW mindestsitze_qpartei_bundesland;
REFRESH MATERIALIZED VIEW sitze_nach_erhoehung;
REFRESH MATERIALIZED VIEW listenmandat;
REFRESH MATERIALIZED VIEW mandat;

SELECT * from listenmandat where wahl = 20;