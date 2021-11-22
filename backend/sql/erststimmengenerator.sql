-- https://stackoverflow.com/questions/988916/postgresql-select-a-single-row-x-amount-of-times

with stimmen as (
    select dk.*, generate_series(1, dk.anzahlstimmen) from direktkandidatur dk
)

insert into erststimme (kandidatur) (select s.direktId from stimmen s);