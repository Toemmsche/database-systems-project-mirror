DROP EXTENSION IF EXISTS "uuid-ossp";

CREATE EXTENSION "uuid-ossp";

DELETE FROM admin_token;

--Admin Tokens fuer die Stimmabgabe (nur 2021)
INSERT into admin_token(token, wahlkreis, gueltig) (
    select uuid_generate_v4(), wk.wkid, TRUE
    from wahlkreis wk
    where wk.wahl = 20
);

--Entferne alte tokens
DELETE
FROM wahl_token;
