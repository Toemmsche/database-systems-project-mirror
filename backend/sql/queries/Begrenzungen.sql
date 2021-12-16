DROP VIEW IF EXISTS begrenzungen CASCADE;

CREATE VIEW begrenzungen(wk_nummer, wk_name, wahl, begrenzung) AS
    SELECT wk.nummer, wk.name, wk.wahl, wk.begrenzung
    FROM wahlkreis wk