# Benchmarking

## Rahmenbedingungen
- Python-Backend mit [waitress](https://pypi.org/project/waitress/) zur Verfügung gestellt
- Benchmarking mit [Locust](https://locust.io/)
- REST-Endpoint mit [Flask](https://flask.palletsprojects.com/en/2.0.x/)
- Backend, PostgreSQL-Datenbank und Benchmarking-Client laufen auf demselben Host

### Verwendete Hardware
- CPU: Intel i5 8400 2.8 GHz (4.2 GHz Boost)
- Hauptspeicher: 16GB DDR4
- Hintergrundspeicher: PCIe SSD (Lesen 3100 MB/s und Schreiben 1600 MB/s)

## Messreihe

### 1. Messreihe
Wartezeit t = 8
Anzahl Terminals n = 10

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/Messreihe_n10_t8.html)

### 2. Messreihe
Wartezeit t = 8
Anzahl Terminals n = 5

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/Messreihe_n5_t8.html)

### 3. Messreihe
Wartezeit t = 8
Anzahl Terminals n = 20

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/Messreihe_n20_t8.html)

### 4. Messreihe

Wartezeit t = 8
Anzahl Terminals n = 50

[Report](https://toemmsche.github.io/DB-Project-Benchmark-Results/Messreihe_n50_t8.html)
