DROP VIEW IF EXISTS begrenzungen CASCADE;

CREATE VIEW begrenzungen(nummer, name, wahl, begrenzung) AS
    SELECT wk.nummer, wk.name, wk.wahl, wk.begrenzung
    FROM wahlkreis wk