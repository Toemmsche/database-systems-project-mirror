# datenbanken-projekt

Repository for the database projekt WS21/22.

# Artefakte
- [Datenenmodell](artifacts/datenmodell.png), bearbeitbar auf [LucidChart](https://lucid.app/lucidchart/e0bc7fdc-b542-4381-9dee-e4d63ecd98c7/edit?invitationId=inv_2f977e18-b0d8-4920-8c90-ede516fe873f)
- [Lastenheft](artifacts/Lastenheft.md)
- [Pflichtenheft](artifacts/Pflichtenheft.md)
- [Vorgehen bei der Berechnung der Sitzverteilung](artifacts/Vorgehen_Sitzberechnung.md)
- [Dokumentation der Stimmabgabe](artifacts/Stimmabgabe.md)
- [Technologiestack](artifacts/TechStack.png)
- [Benchmark-Ergebnisse](TODO)
- [Abschlusspräsentation](TODO)

# Installation

## Voraussetzungen
- Linux
- [PostgreSQL](https://www.postgresql.org/) (Ver. 14 empfohlen)
- [python](https://www.python.org/) (>= 3.9 empfohlen) mit [pip](https://pypi.org/project/pip/)
- [Node.js](https://nodejs.org/en/) (>= 16.x.x empfohlen) mit [npm](https://www.npmjs.com/)


## Vorgehen
- Klone dieses Repository:

```git clone https://gitlab.db.in.tum.de/Toemmsche/datenbanken-projekt.git```

- Lege in PostgreSQL eine neue Datenbank an und setze die Umgebungsvariable `$DATABASE_URL` auf den entsprenden Connection string.
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
