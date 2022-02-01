DROP TABLE IF EXISTS bundestagswahl CASCADE;
DROP TABLE IF EXISTS bundesland CASCADE;
DROP TABLE IF EXISTS wahlkreis CASCADE;
DROP TABLE IF EXISTS strukturdaten CASCADE;
DROP TABLE IF EXISTS gemeinde CASCADE;
DROP TABLE IF EXISTS partei CASCADE;
DROP TABLE IF EXISTS kandidat CASCADE;
DROP TABLE IF EXISTS direktkandidatur CASCADE;
DROP TABLE IF EXISTS landesliste CASCADE;
DROP TABLE IF EXISTS listenplatz CASCADE;
DROP TABLE IF EXISTS erststimme CASCADE;
DROP TABLE IF EXISTS zweitstimme CASCADE;
DROP TABLE IF EXISTS ungueltige_stimme CASCADE;
DROP TABLE IF EXISTS ungueltige_stimmen_ergebnis;
DROP TABLE IF EXISTS zweitstimmenergebnis CASCADE;
DROP TABLE IF EXISTS admin_token CASCADE;
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
    wappen  BYTEA,
    landid  INTEGER PRIMARY KEY
);

CREATE TABLE wahlkreis
(
    nummer     INTEGER                                    NOT NULL,
    name       VARCHAR(100)                               NOT NULL,
    land       INTEGER REFERENCES bundesland (landid)     NOT NULL,
    wahl       INTEGER REFERENCES bundestagswahl (nummer) NOT NULL,
    deutsche   INTEGER                                    NOT NULL,
    begrenzung TEXT                                       NOT NULL,
    wkid       SERIAL PRIMARY KEY,
    UNIQUE (nummer, wahl),
    UNIQUE (name, wahl)
);

CREATE TABLE strukturdaten
(
    wahlkreis                                                      INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    auslaenderanteil                                               DECIMAL                             NOT NULL,
    bevoelkerungsdichte                                            DECIMAL                             NOT NULL,
    bevoelkerungsveraenderung_pro_1000_ew                          DECIMAL                             NOT NULL,
    altersanteil_unter_18                                          DECIMAL                             NOT NULL,
    altersanteil_18_bis_24                                         DECIMAL                             NOT NULL,
    altersanteil_25_bis_34                                         DECIMAL                             NOT NULL,
    altersanteil_35_bis_59                                         DECIMAL                             NOT NULL,
    altersanteil_60_bis_74                                         DECIMAL                             NOT NULL,
    altersanteil_ueber_74                                          DECIMAL                             NOT NULL,
    bodenflaechenanteil_siedlung_verkehr                           DECIMAL,
    bodenflaechenanteil_vegation_gewaesser                         DECIMAL,
    wohnungen_pro_1000_ew                                          DECIMAL                             NOT NULL,
    wohnflaeche_pro_wohnung                                        DECIMAL,
    wohnflaeche_pro_ew                                             DECIMAL,
    pkw_bestand_pro_1000_ew                                        DECIMAL                             NOT NULL,
    pkw_anteil_elektro_hybrid                                      DECIMAL,
    unternehmen_pro_1000_ew                                        DECIMAL                             NOT NULL,
    handwerksunternehmen_pro_1000_ew                               DECIMAL                             NOT NULL,
    schulabgaenger_beruflich_pro_1000_ew                           DECIMAL,
    schulabgaenger_allgemeinbildend_pro_1000_ew                    DECIMAL                             NOT NULL,
    schulabgaengeranteil_allgemeinbildend_ohne_hauptschulabschluss DECIMAL                             NOT NULL,
    schulabgaengeranteil_allgemeinbildend_hauptschulabschluss      DECIMAL                             NOT NULL,
    schulabgaengeranteil_allgemeinbildend_mittlerer_schulabschluss DECIMAL                             NOT NULL,
    schulabgaengeranteil_allgemeinbildend_hochschulreife           DECIMAL                             NOT NULL,
    einkommen_pro_ew                                               DECIMAL                             NOT NULL,
    bip_pro_ew                                                     DECIMAL                             NOT NULL,
    beschaeftigte_pro_1000_ew                                      DECIMAL                             NOT NULL,
    beschaeftigtenanteil_landwirtschaft_forstwirtschaft_fischerei  DECIMAL,
    beschaeftigtenanteil_produzierendes_gewerbe                    DECIMAL,
    beschaeftigtenanteil_handel_gastgewerbe_verkehr                DECIMAL,
    beschaeftigtenanteil_dienstleister                             DECIMAL,
    leistungsempfaenger_pro_1000_ew                                DECIMAL                             NOT NULL,
    arbeitslosenquote                                              DECIMAL                             NOT NULL,
    arbeitslosenquote_maenner                                      DECIMAL                             NOT NULL,
    arbeitslosenquote_frauen                                       DECIMAL                             NOT NULL,
    arbeitslosenquote_15_bis_24                                    DECIMAL,
    arbeitslosenquote_55_bis_64                                    DECIMAL                             NOT NULL
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
    logo                BYTEA,
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

CREATE TABLE ungueltige_stimme
(
    stimmentyp INTEGER NOT NULL,
    wahlkreis  INTEGER REFERENCES wahlkreis (wkid)
);

CREATE TABLE ungueltige_stimmen_ergebnis
(
    stimmentyp    INTEGER NOT NULL,
    wahlkreis     INTEGER REFERENCES wahlkreis (wkid),
    anzahlstimmen INTEGER,
    PRIMARY KEY (stimmentyp, wahlkreis)
);

CREATE TABLE zweitstimmenergebnis
(
    liste         INTEGER REFERENCES landesliste (listenid) NOT NULL,
    wahlkreis     INTEGER REFERENCES wahlkreis (wkid)       NOT NULL,
    anzahlstimmen INTEGER,
    PRIMARY KEY (liste, wahlkreis)
);

CREATE TABLE admin_token
(
    wahlkreis INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    token     UUID PRIMARY KEY,
    gueltig   BOOLEAN                             NOT NULL
);

CREATE TABLE wahl_token
(
    wahlkreis INTEGER REFERENCES wahlkreis (wkid) NOT NULL,
    token     UUID PRIMARY KEY,
    gueltig   BOOLEAN                             NOT NULL
)