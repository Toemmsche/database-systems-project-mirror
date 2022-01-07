DROP EXTENSION IF EXISTS "uuid-ossp";

CREATE EXTENSION "uuid-ossp";

DELETE
FROM token;

--Tokens fuer Stimmabgabe (nur 2021)
WITH tokens AS (
    SELECT wkid AS wahlkreis, GENERATE_SERIES(1, wk.deutsche)
    FROM wahlkreis wk
    WHERE wk.wahl = 20
)
INSERT
INTO wahl_token (token, wahlkreis, gueltig)
        (SELECT uuid_generate_v4(), t.wahlkreis, TRUE FROM tokens t);