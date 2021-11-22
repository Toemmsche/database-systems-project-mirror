-- https://stackoverflow.com/questions/988916/postgresql-select-a-single-row-x-amount-of-times

with stimmen as (
    select zse.*, generate_series(1, zse.anzahlstimmen) from zweitstimmenergebnis zse
)

insert into zweitstimme (liste, wahlkreis) (select s.liste, s.wahlkreis from stimmen s);