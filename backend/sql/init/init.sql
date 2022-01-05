DROP TABLE IF EXISTS bundestagswahl CASCADE;
DROP TABLE IF EXISTS bundesland CASCADE;
DROP TABLE IF EXISTS wahlkreis CASCADE;
DROP TABLE IF EXISTS gemeinde CASCADE;
DROP TABLE IF EXISTS partei CASCADE;
DROP TABLE IF EXISTS kandidat CASCADE;
DROP TABLE IF EXISTS direktkandidatur CASCADE;
DROP TABLE IF EXISTS landesliste CASCADE;
DROP TABLE IF EXISTS listenplatz CASCADE;
DROP TABLE IF EXISTS erststimme CASCADE;
DROP TABLE IF EXISTS zweitstimme CASCADE;
DROP TABLE IF EXISTS zweitstimmenergebnis CASCADE;
DROP TABLE IF EXISTS wahl_token CASCADE;

CREATE TABLE bundestagswahl
(
    tag    DATE UNIQUE NOT NULL,
    nummer INTEGER PRIMARY KEY
);

CREATE TABLE bundesland
(
    kuerzel CHAR(2) UNIQUE NOT NULL,
    name    VARCHAR(50),
    osten   BOOLEAN        NOT NULL,
    wappen  bytea,
    landid  INTEGER PRIMARY KEY
);

CREATE TABLE wahlkreis
(
    nummer            INTEGER                                    NOT NULL,
    name              VARCHAR(100)                               NOT NULL,
    land              INTEGER REFERENCES bundesland (landid)     NOT NULL,
    wahl              INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    deutsche          INTEGER                                    NOT NULL,
    begrenzung        TEXT                                       NOT NULL,
    arbeitslosenquote DECIMAL                                    NOT NULL,
    wkid              SERIAL PRIMARY KEY,
    UNIQUE (nummer, wahl),
    UNIQUE (name, wahl)
);

CREATE TABLE gemeinde
(

    name       VARCHAR(100)                        NOT NULL,
    plz        CHAR(5),
    wahlkreis  INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    zusatz     VARCHAR(100),
    gemeindeid SERIAL PRIMARY KEY
    --UNIQUE (name, plz, wahlkreis)
);

CREATE TABLE partei
(

    name                VARCHAR(100) UNIQUE NOT NULL,
    kuerzel             VARCHAR(40),
    nationaleminderheit BOOLEAN             NOT NULL,
    gruendungsjahr      INTEGER,
    farbe               VARCHAR(6),
    logo                bytea,
    parteiid            SERIAL PRIMARY KEY
);
CREATE TABLE kandidat
(

    vorname     VARCHAR(100) NOT NULL,
    nachname    VARCHAR(60)  NOT NULL,
    titel       VARCHAR(50),
    zusatz      VARCHAR(50),
    geburtsjahr INTEGER      NOT NULL,
    geburtsort  VARCHAR(200) NOT NULL,
    wohnort     VARCHAR(200),
    beruf       VARCHAR(200) NOT NULL,
    geschlecht  VARCHAR(20)  NOT NULL,
    kandid      SERIAL PRIMARY KEY,
    UNIQUE (vorname, nachname, geburtsjahr, geburtsort)
);

CREATE TABLE direktkandidatur
(

    partei               INTEGER REFERENCES partei (parteiid),
    parteilosgruppenname VARCHAR(200),
    kandidat             INTEGER REFERENCES kandidat (kandid),
    wahlkreis            INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    anzahlstimmen        INTEGER,
    direktid             SERIAL PRIMARY KEY
);

CREATE TABLE landesliste
(

    partei              INTEGER REFERENCES partei (parteiid)       NOT NULL,
    wahl                INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    land                INTEGER REFERENCES bundesland (landid)     NOT NULL,
    stimmzettelposition INTEGER                                    NOT NULL,
    listenid            SERIAL PRIMARY KEY,
    UNIQUE (partei, wahl, land)
);

-- Constraint damit kein Kandidat in zwei Landeslistenfür eine Wahl antritt
CREATE TABLE listenplatz
(
    position INTEGER                                   NOT NULL,
    kandidat INTEGER REFERENCES kandidat (kandid)      NOT NULL,
    liste    INTEGER REFERENCES landesliste (listenid) NOT NULL,
    PRIMARY KEY (liste, position)
);

CREATE TABLE erststimme
(
    kandidatur INTEGER REFERENCES direktkandidatur (direktid) NOT NULL
);

CREATE TABLE zweitstimme
(
    liste     INTEGER REFERENCES landesliste (listenid),
    wahlkreis INTEGER REFERENCES wahlkreis (wkid)
);

CREATE TABLE zweitstimmenergebnis
(
    liste         INTEGER REFERENCES landesliste (listenid) NOT NULL,
    wahlkreis     INTEGER REFERENCES wahlkreis (wkid)       NOT NULL,
    anzahlstimmen INTEGER,
    PRIMARY KEY (liste, wahlkreis)
);

CREATE TABLE wahl_token
(
    wahlkreis INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    token     TEXT                                NOT NULL,
    gueltig   BOOLEAN                             NOT NULL,
    PRIMARY KEY (wahlkreis, token)
)