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
    landId CHAR(2) PRIMARY KEY,
    name   VARCHAR(50),
    osten  BIT NOT NULL,
    wappen BYTEA
);

CREATE TABLE Wahlkreis
(
    wkId       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nummer     INTEGER                                    NOT NULL,
    wahl       INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    deutsche   INTEGER                                    NOT NULL,
    begrenzung BYTEA,
    UNIQUE (nummer, wahl)
);

CREATE TABLE Gemeinde
(
    gemeindeId INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100)                        NOT NULL,
    plz        CHAR(5),
    wahlkreis  INTEGER REFERENCES Wahlkreis (wkId) NOT NULL,
    zusatz     VARCHAR(100),
    UNIQUE (plz, wahlkreis)
);

CREATE TABLE Partei
(
    name                VARCHAR(100) UNIQUE NOT NULL,
    kuerzel             VARCHAR(20) PRIMARY KEY,
    nationaleMinderheit BIT                 NOT NULL,
    gruendungsjahr      INTEGER,
    farbe               VARCHAR(6),
    logo                BYTEA
);
CREATE TABLE Kandidat
(
    kandId     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vorname    VARCHAR(100)                             NOT NULL,
    nachname   VARCHAR(60)                              NOT NULL,
    titel      VARCHAR(50)                              NOT NULL,
    zusatz     VARCHAR(50)                              NOT NULL,
    geburtstag DATE                                     NOT NULL,
    geburtsort VARCHAR(200)                             NOT NULL,
    wohnort    INTEGER REFERENCES Gemeinde (gemeindeId) NOT NULL,
    beruf      VARCHAR(200)                             NOT NULL,
    geschlecht VARCHAR(20)                              NOT NULL,
    partei     VARCHAR(20) REFERENCES Partei (kuerzel)  NOT NULL,
    UNIQUE (vorname, nachname, geburtstag)
);

CREATE TABLE Direktkandidatur
(
    direktId      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partei        VARCHAR(20) REFERENCES Partei (kuerzel),
    kandidat      INTEGER REFERENCES Kandidat (kandId)       NOT NULL,
    wahl          INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    wahlkreis     INTEGER REFERENCES Wahlkreis (wkId)        NOT NULL,
    anzahlStimmen INTEGER
);

CREATE TABLE Landesliste
(
    listenId            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partei              VARCHAR(20) REFERENCES Partei (kuerzel)    NOT NULL,
    wahl                INTEGER REFERENCES Bundestagswahl (nummer) NOT NULL,
    land                VARCHAR(50) REFERENCES Bundesland (landId) NOT NULL,
    stimmzettelPosition INTEGER                                    NOT NULL,
    UNIQUE (partei, wahl, land)
);

-- Constraint damit kein Kandidat in zwei Landeslistenfür eine Wahl antritt
CREATE TABLE Listenplatz
(
    position INTEGER                                   NOT NULL,
    kandidat INTEGER REFERENCES Kandidat (kandId)      NOT NULL,
    liste    INTEGER REFERENCES Landesliste (listenId) NOT NULL,
    PRIMARY KEY (liste, position)
);

CREATE TABLE Erststimme
(
    erstId     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    wahlkreis  INTEGER REFERENCES Wahlkreis (wkId)            NOT NULL,
    kandidatur INTEGER REFERENCES Direktkandidatur (direktId) NOT NULL,
    briefwahl  BIT,
    gueltig    BIT                                            NOT NULL
);

CREATE TABLE Zweitstimme
(
    zweitId   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    liste     INTEGER REFERENCES Landesliste (listenId),
    gueltig   BIT NOT NULL,
    briefwahl BIT
);

CREATE TABLE Zweitstimmenergebnis
(
    liste         INTEGER REFERENCES Landesliste (listenId) NOT NULL,
    wahlkreis     INTEGER REFERENCES Wahlkreis (wkId)       NOT NULL,
    anzahlStimmen INTEGER,
    PRIMARY KEY (liste, wahlkreis)
);