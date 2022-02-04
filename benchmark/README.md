# Benchmarking

## Rahmenbedingungen
- Linux 5.11 (Kubuntu)
- Datenbank: [PostgreSQL 14](https://www.postgresql.org/)
- Backend: [Python 3.9](https://www.python.org/)
  - Datenbankadapter: [psycopg 3](https://www.psycopg.org/)
  - Webframework: [Flask](https://flask.palletsprojects.com/en/2.0.x/)
  - WSGI server: [gunicorn](https://gunicorn.org/) skaliert auf 12 Worker
- Benchmarking: [Locust](https://locust.io/)


### Verwendete Hardware
- CPU: Intel i5 8400 6 x 2.8 GHz (4.2 GHz Boost)
- Hauptspeicher: 16GB DDR4
- Hintergrundspeicher: PCIe SSD (Lesen 3100 MB/s und Schreiben 1600 MB/s)

## Weitere Anmerkungen

Aus Performancegründen werden die Ergebnisse der "Bundestags-Query" in einer materialisierten Sicht gehalten. Beim Einfügen von neuen Stimmen wird diese Sicht jeweils neu berechnet, sodass stets das aktuellste Ergebnis sichtbar ist.

## Reproduktion

Voraussetzungen: [Python](https://www.python.org/) und [gunicorn](https://gunicorn.org/)

Starten des backends:
```
cd backend
pip install -r requirements.txt
sh gunicorn.sh
```
Starten von locust:
```
cd benchmark
pip install -r requirements.txt
locust
```

Die Benchmarkingschnittstelle sollte unter `http://localhost:8089` erreichbar sein. Zum Anpassen des Parameters **t** muss
`locustfile.py` geändert werden. **n** kann in der Webschnittstelle angepasst werden.

## Messreihen (Linux)

### 1. Messreihe

Wartezeit t = 10, Anzahl Terminals n = 100

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/t=10_n=100.html)

### 2. Messreihe

Wartezeit t = 1, Anzahl Terminals n = 100

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/t=1_n=100.html)

### 3. Messreihe

Wartezeit t = 1, Anzahl Terminals n = 500

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/t=1_n=500.html)

### 4. Messreihe

Wartezeit t = 0.1, Anzahl Terminals n = 100

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/t=0.1_n=100.html)

### 5. Messreihe

Wartezeit t = 1, Anzahl Terminals n = 500

Der Wahlkreis wird diesmal zufällig ausgewählt. Dadurch lassen sich jedoch keine Performanceunterschiede zur  3. Messreihe beobachten, weswegen bei vorherigen Messreihen ein fester Wahlkreis aus Gründen der Übersichtlichkeit gewählt wurde.


[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/t=1_n=500_random_wk.html)