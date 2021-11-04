# Lastenheft
## Benutzerschnittstelle(n)
- (REST-)API mit Zugriff auf Kernfunktionen 
- Webseite mit interaktiver Deutschlandkarte, unterteilt in (Bundes-)Länder und Wahlkreise
    
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
- Interessante Statistiken berechnen und visualisieren:
	- Knappester/Deutlichster Erststimmensieg
	- Anteil Briefwahl
	- Anteil ungültiger Stimmen
	- Wählerumzug (nur innerhalb von Wahlkreisen)
	- Größter Gewinner/Verlierer
	- Frauenanteil im Bundestag
	- ...
## Nichtfunktionale Anforderungen
- **Usability**:
	- Wenig Klicks zum Ergebnis
- **Reliability**
	- Robust gegenüber fehlerhaften Eingaben oder fehlenden Berichtigungen
	- Keine Anfragen durch Endnutzer
- **Performance**:
	- Geeignet für knapp 2*60Mio. Stimmeingaben innerhalb des Wahlzeitfensters.
	- (Neu-)Berechnung der genauen Sizverteilung im Bundestag innerhalb von 2s (Speichermedium: SSD)
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
- Ausführliche Versionierung und Artefakte sind vorhanden