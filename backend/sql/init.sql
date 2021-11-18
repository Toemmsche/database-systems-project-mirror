DROP TABLE IF EXISTS Bundestagswahl CASCADE;
DROP TABLE IF EXISTS Bundesland CASCADE;
DROP TABLE IF EXISTS Wahlkreis CASCADE;
DROP TABLE IF EXISTS Gemeinde CASCADE;
DROP TABLE IF EXISTS Partei CASCADE;
DROP TABLE IF EXISTS Kandidat CASCADE;
DROP TABLE IF EXISTS Direktkandidatur CASCADE;
DROP TABLE IF EXISTS Landesliste CASCADE;
DROP TABLE IF EXISTS Listenplatz CASCADE;
DROP TABLE IF EXISTS Erststimme CASCADE;
DROP TABLE IF EXISTS Zweitstimme CASCADE;
DROP TABLE IF EXISTS Zweitstimmenergebnis CASCADE;

CREATE TABLE Bundestagswahl
(
    nummer INTEGER PRIMARY KEY,
    tag    DATE UNIQUE NOT NULL
);

CREATE TABLE Bundesland
(
    landId  INTEGER PRIMARY KEY,
    kuerzel CHAR(2) UNIQUE NOT NULL,
    name    VARCHAR(50),
    osten   BIT            NOT NULL,
    wappen  BYTEA
);

CREATE TABLE Wahlkreis
(
    wkId       UUID PRIMARY KEY,
    nummer     INTEGER                                    NOT NULL,
    name       VARCHAR(100)                               NOT NULL,
    land       INTEGER REFERENCES Bundesland (landId)     NOT NULL,
    wahl       INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    deutsche   INTEGER                                    NOT NULL,
    begrenzung BYTEA,
    UNIQUE (nummer, wahl),
    UNIQUE (name, wahl)
);

CREATE TABLE Gemeinde
(
    gemeindeId UUID PRIMARY KEY,
    name       VARCHAR(100)                     NOT NULL,
    plz        CHAR(5),
    wahlkreis  UUID REFERENCES Wahlkreis (wkId) NOT NULL,
    zusatz     VARCHAR(100)
    --UNIQUE (name, plz, wahlkreis)
);

CREATE TABLE Partei
(
    parteiId            INTEGER PRIMARY KEY,
    name                VARCHAR(100) UNIQUE NOT NULL,
    kuerzel             VARCHAR(40),
    nationaleMinderheit BIT                 NOT NULL,
    gruendungsjahr      INTEGER,
    farbe               VARCHAR(6),
    logo                BYTEA
);
CREATE TABLE Kandidat
(
    kandId      UUID PRIMARY KEY,
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

CREATE TABLE Direktkandidatur
(
    direktId             UUID PRIMARY KEY,
    partei               INTEGER REFERENCES Partei (parteiId),
    parteilosGruppenname VARCHAR(200),
    kandidat             UUID REFERENCES Kandidat (kandId),
    wahl                 INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    wahlkreis            UUID REFERENCES Wahlkreis (wkId)           NOT NULL,
    anzahlStimmen        INTEGER
);

CREATE TABLE Landesliste
(
    listenId            UUID PRIMARY KEY,
    partei              INTEGER REFERENCES Partei (parteiId)       NOT NULL,
    wahl                INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    land                INTEGER REFERENCES Bundesland (landId)     NOT NULL,
    stimmzettelPosition INTEGER                                    NOT NULL,
    UNIQUE (partei, wahl, land)
);

-- Constraint damit kein Kandidat in zwei Landeslistenfür eine Wahl antritt
CREATE TABLE Listenplatz
(
    position INTEGER                                NOT NULL,
    kandidat UUID REFERENCES Kandidat (kandId)      NOT NULL,
    liste    UUID REFERENCES Landesliste (listenId) NOT NULL,
    PRIMARY KEY (liste, position)
);

CREATE TABLE Erststimme
(
    erstId     UUID PRIMARY KEY,
    kandidatur UUID REFERENCES Direktkandidatur (direktId) NOT NULL
);

CREATE TABLE Zweitstimme
(
    zweitId   UUID PRIMARY KEY,
    liste     UUID REFERENCES Landesliste (listenId),
    gueltig   BIT NOT NULL,
    wahlkreis UUID REFERENCES Wahlkreis (wkId)
);

CREATE TABLE Zweitstimmenergebnis
(
    liste         UUID REFERENCES Landesliste (listenId) NOT NULL,
    wahlkreis     UUID REFERENCES Wahlkreis (wkId)       NOT NULL,
    anzahlStimmen INTEGER,
    PRIMARY KEY (liste, wahlkreis)
);