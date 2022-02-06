# Wahlinformationssystem

Unser [Wahlinformationssystem](https://datenbanken-ws22-frontend.herokuapp.com/) und die zugehörige 
 [API](https://datenbanken-ws22.herokuapp.com/api/) ist für jeden zugänglich.

Eine [interaktive Übersicht](https://switcherlapp97.github.io/) ist ebenfalls verfügbar.

# Artefakte
- [Datenenmodell](artifacts/datenmodell.png), bearbeitbar auf [LucidChart](https://lucid.app/lucidchart/e0bc7fdc-b542-4381-9dee-e4d63ecd98c7/edit?invitationId=inv_2f977e18-b0d8-4920-8c90-ede516fe873f)
- [Lastenheft](artifacts/Lastenheft.md)
- [Pflichtenheft](artifacts/Pflichtenheft.md)
- [Vorgehen bei der Berechnung der Sitzverteilung](artifacts/Vorgehen_Sitzberechnung.md)
- [Dokumentation der Stimmabgabe](artifacts/Stimmabgabe.md)
- [Technologiestack](artifacts/TechStack.png)
- [Benchmark-Ergebnisse](benchmark/README.md)
- [Abschlusspräsentation](artifacts/abschlusspraesentation.pdf)


# Projektübersicht

## Artefakte (/artifacts)

Sämtliche Artefakte und Dokumentation, wie sie oben aufgelistet sind.

## Backend (/backend)

- data/
  - Datenquellen (hauptsächlich vom Bundeswahlleiter)
- logic/
  - Einlesen der Daten ([initialization](/backend/logic/Initialization.py))
  - Applikationslogik (mit z.T. eingebetettem SQL)
  - Hilfsfunktionen zur Kommunikation mit der Datenbank
- sql/
  - bundestag/
    - Berechnung der Sitzverteilung und Mandat
    - Besondere Trigger
  - init/
    - Schemaerstellung ([init.sql](/backend/sql/init/init.sql))
    - Indizes
    - Trigger
  - queries/
    - Daten, die an das Frontend weitergegeben werden
- test/
  - Korrrekt der Sitzverteilung
  - Korrektheit der Überhangmandate
  - Korrektheit der MDB
- server.py
  - API-Schnittstelle

## Benchmarking (/benchmark)

- locustfile.py
  - Definition des Benchmarks (Wartezeit t und Anfrageverteilung)
- results/
  - Messreihen

## Frontend (/frontend)
Hier liegen sämtliche Dateien und Logik, die für die Visualisierung und Bereitstellung der Webschnittstelle benötigt werden.


# Installation

## Voraussetzungen
- Linux
- [PostgreSQL](https://www.postgresql.org/) (Ver. 14 empfohlen)
- [python](https://www.python.org/) (>= 3.9 empfohlen) mit [pip](https://pypi.org/project/pip/)
- [Node.js](https://nodejs.org/en/) (>= 16.x.x empfohlen) mit [npm](https://www.npmjs.com/)
- Evtl. muss [libpq-dev](https://datenbanken-ws22-frontend.herokuapp.com/) installiert werden.


## Vorgehen
- Klone dieses Repository:

```git clone https://gitlab.db.in.tum.de/Toemmsche/datenbanken-projekt.git```

- Lege in PostgreSQL eine neue Datenbank an und setze die Umgebungsvariable `$DATABASE_URL` auf den entsprenden [Connection string](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING).
- Starte das Backend:
  
```
cd backend
pip install -r requirements.txt
python waitress_server.py
```
Nach einer kurzen Initialisierungsphase sollte `INFO:waitress:Serving on http://0.0.0.0:5000` ausgegeben werden.
- Starte das Frontend:

```
cd frontend
npm install -g @angular/cli
npm install
ng serve
```
Nach einer kurzen Wartezeit sollte die Benutzeroberfläche unter `http://localhost:4200` erreichbar sein.

## Testen
Zum Ausführen der Tests wird eine laufende Version der Datenbank benötigt.
```
cd backend
pip install -r requirements.txt
export $DATABASE_URL=(connection_string)
python -m unittest test/*.py
```

