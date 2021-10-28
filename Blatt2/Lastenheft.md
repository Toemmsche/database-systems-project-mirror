# Lastenheft
## Benutzerschnittstelle
- REST-API
- Interaktive Map

## Funktionale Anforderungen
- identische Funktionalität für Wahl 2017 und 2021
- Sitzverteilung des Bundestags berechnen, ausgeben und visualisieren
- Erst- und Zweitstimmenergebnis pro Bundesland/Wahlkreis ausgeben und visualisieren (Kreisdiagramm)
- Vergleich der Wahlergebnisse ggü. 2017 auf Bundes-, Landes-, und Wahlkreisebene
- Heatmap für jede Partei anzeigen
- Interessante Statistiken berechnen und visualisieren:
  - Knappester/Deutlichster Erststimmensieg
  - Anteil Briefwahl
  - Anteil ungültiger Stimmen
  - Wählerumzug
  - Größter Gewinner/Verliere
  - Frauenanteil im Bundestag
  - ...
- Stimmabgabe analog zum Wahllokal
- Ausgaben der Kandidaten- und Landeslisten
- Ausgabe der Wahlkreisdaten pro Bundesland
- Übersicht über Funktionen auf Landing Page

## Nichtfunktionale Anforderungen
- Ca. 50 Mio. Wähler
- Durchsatz 100 Mio. Erst- und Zweitstimmen (INSERTS) über 15h (9 bis 18 Uhr Lokal, 18  bis 24 Uhr Briefwähler) verteilt
- Neuberechnung der Bundestagssitze in max. 2s
- Hohe Benutzbarkeit: Wenig Klicks zum Ergebnis
- Keine custom Nutzeranfragen
- Robust gegenüber fehlerhaften Eingaben oder fehlenden Berichtigungen
- Läuft auf gängigen Webbrowsern
## Constraints
- Nutzen eines relationalen DBMS
- DSGVO-Konformität

## Abnahmekriterien
- 100% korrekte Berechnung der Sitzverteilung unter Berücksichtigung relevanter Sonderregelungen
  - 5% Hürde
  - Überhangsmandate (außer die ersten drei)
  - nationale Minderheiten
- Stimmeingabe funktioniert und identifiziert Fehlerfälle rechtzeitig
- Ausführliche Versionierung und Artefakte