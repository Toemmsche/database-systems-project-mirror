# Lastenheft
## Projektbeschreibung
Es soll ein Informationssystem für die deutsche Bundestagswahl entwickelt werden. Das System soll Analysen des Wahlergebnisses (z.B. Sitzverteilung im Bundestag, Vergleiche mit vergangenen Bundestagswahlen) ermöglichen und insbesondere auch die Zusammensetzung des Bundestags berechnen können.

## Benutzerschnittstelle(n)
- Webseite mit interaktiver Deutschlandkarte, unterteilt in (Bundes-)Länder und Wahlkreise
- (REST-)API als Schnittstelle zwischen Datenbank und Webseite mit Zugriff auf Kernfunktionen 
    
## Funktionale Anforderungen
Grundsätzlich wird identische Funktionalität für die BTW 2017 (und älter) wie für die BTW 2021 (und neuer) gefordert.
### Kernfunktionen
- Sitzverteilung des Bundestags berechnen, ausgeben und visualisieren
- Erst- und Zweitstimmenergebnis pro Bundesland/Wahlkreis ausgeben und visualisieren (Kreisdiagramm)
- Vergleich der Wahlergebnisse ggü. 2017 auf Bundes-, Landes-, und Wahlkreisebene
- Stimmabgabe möglich
### Weitere Anforderungen
- Heatmaps für jede Partei, die zeigen, in welchen Gebieten ein Partei am stärksten abgeschnitten hat
- Ausgaben der Kandidaten- und Landeslisten
- Ausgabe der Wahlkreisdaten pro Bundesland
- Suchfunktion für Wahlkreise, Kandidaten, und Parteien
- Interessante Statistiken berechnen und visualisieren:
	- Knappster/Deutlichster Erststimmensieg
	- Anteil Briefwahl
	- Anteil ungültiger Stimmen
	- Wählerumzug (nur innerhalb von Wahlkreisen)
	- Größter Gewinner/Verlierer
	- Frauenanteil im Bundestag
	- ...
## Nichtfunktionale Anforderungen
- **Usability**:
	- Wenige Klicks zum Ergebnis
- **Reliability**
	- Robust gegenüber fehlerhaften Eingaben oder fehlenden Berichtigungen
	- Keine Anfragen durch Endnutzer
- **Performance**:
	- Geeignet für knapp 2*60Mio. Stimmeingaben innerhalb des Wahlzeitfensters.
	- (Neu-)Berechnung der genauen Sizverteilung im Bundestag innerhalb von 2s (Speichermedium: SSD)
	- effiziente Analysen auf universellen Datenbanksystemen und Consumer-Hardware ermöglichen
    - Möglichkeit pro Wahlkreis Einzelstimmen zu Wahlkreisergebnissen vorzuaggregieren
- **Supportability**:
	- Bedienbar auf allen gängigen Webbrowsern

## Constraints
- Nutzen eines relationalen DBMS
- DSGVO-Konformität

## Abnahmekriterien
- 100% korrekte Berechnung der Sitzverteilung unter Berücksichtigung relevanter Sonderregelungen
  - 5% Hürde
  - Überhangsmandate (außer die ersten drei)
  - nationale Minderheiten
- Stimmeingabe funktioniert und identifiziert mögliche Fehlerfälle
- Direkter Vergleich mit der BTW 2017 ist möglich
- Ausführliche Versionierung und Artefakte sind vorhanden
