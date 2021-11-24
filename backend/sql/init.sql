DROP DATABASE IF EXISTS wahl;
CREATE DATABASE wahl;

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

CREATE TABLE bundestagswahl
(
    nummer INTEGER PRIMARY KEY,
    tag    DATE UNIQUE NOT NULL
);

CREATE TABLE bundesland
(
    landid  INTEGER PRIMARY KEY,
    kuerzel CHAR(2) UNIQUE NOT NULL,
    name    VARCHAR(50),
    osten   BIT            NOT NULL,
    wappen  bytea
);

CREATE TABLE wahlkreis
(
    wkid       uuid PRIMARY KEY,
    nummer     INTEGER                                    NOT NULL,
    name       VARCHAR(100)                               NOT NULL,
    land       INTEGER REFERENCES bundesland (landid)     NOT NULL,
    wahl       INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    deutsche   INTEGER                                    NOT NULL,
    begrenzung bytea,
    UNIQUE (nummer, wahl),
    UNIQUE (name, wahl)
);

CREATE TABLE gemeinde
(
    gemeindeid uuid PRIMARY KEY,
    name       VARCHAR(100)                     NOT NULL,
    plz        CHAR(5),
    wahlkreis  uuid REFERENCES wahlkreis (wkid) NOT NULL,
    zusatz     VARCHAR(100)
    --UNIQUE (name, plz, wahlkreis)
);

CREATE TABLE partei
(
    parteiid            INTEGER PRIMARY KEY,
    name                VARCHAR(100) UNIQUE NOT NULL,
    kuerzel             VARCHAR(40),
    nationaleminderheit BIT                 NOT NULL,
    gruendungsjahr      INTEGER,
    farbe               VARCHAR(6),
    logo                bytea
);
CREATE TABLE kandidat
(
    kandid      uuid PRIMARY KEY,
    vorname     VARCHAR(100) NOT NULL,
    nachname    VARCHAR(60)  NOT NULL,
    titel       VARCHAR(50),
    zusatz      VARCHAR(50),
    geburtsjahr INTEGER      NOT NULL,
    geburtsort  VARCHAR(200) NOT NULL,
    wohnort     VARCHAR(200),
    beruf       VARCHAR(200) NOT NULL,
    geschlecht  VARCHAR(20)  NOT NULL,
    UNIQUE (vorname, nachname, geburtsjahr, geburtsort)
);

CREATE TABLE direktkandidatur
(
    direktid             uuid PRIMARY KEY,
    partei               INTEGER REFERENCES partei (parteiid),
    parteilosgruppenname VARCHAR(200),
    kandidat             uuid REFERENCES kandidat (kandid),
    wahl                 INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    wahlkreis            uuid REFERENCES wahlkreis (wkid)           NOT NULL,
    anzahlstimmen        INTEGER
);

CREATE TABLE landesliste
(
    listenid            uuid PRIMARY KEY,
    partei              INTEGER REFERENCES partei (parteiid)       NOT NULL,
    wahl                INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    land                INTEGER REFERENCES bundesland (landid)     NOT NULL,
    stimmzettelposition INTEGER                                    NOT NULL,
    UNIQUE (partei, wahl, land)
);

-- Constraint damit kein Kandidat in zwei Landeslistenfür eine Wahl antritt
CREATE TABLE listenplatz
(
    position INTEGER                                NOT NULL,
    kandidat uuid REFERENCES kandidat (kandid)      NOT NULL,
    liste    uuid REFERENCES landesliste (listenid) NOT NULL,
    PRIMARY KEY (liste, position)
);

CREATE TABLE erststimme
(
    kandidatur uuid REFERENCES direktkandidatur (direktid) NOT NULL
);

CREATE TABLE zweitstimme
(
    liste     uuid REFERENCES landesliste (listenid),
    wahlkreis uuid REFERENCES wahlkreis (wkid)
);

CREATE TABLE zweitstimmenergebnis
(
    liste         uuid REFERENCES landesliste (listenid) NOT NULL,
    wahlkreis     uuid REFERENCES wahlkreis (wkid)       NOT NULL,
    anzahlstimmen INTEGER,
    PRIMARY KEY (liste, wahlkreis)
);