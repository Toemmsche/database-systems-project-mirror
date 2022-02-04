# Lastenheft
## Projektbeschreibung
Es soll ein Wahlinformationssystem für die deutsche Bundestagswahl entwickelt werden.
Das System soll Analysen von den Bundestagswahlen 2017 und 2021 ermöglichen und insbesondere auch die Zusammensetzung des Bundestags berechnen können.

## Benutzerschnittstellen
Das Wahlinformationssystem stellt eine Webanwendung zur Verfügung.
Diese visualisiert Wahlergebnisse und diverse Statistiken auf Wahlkreisebene mithilfe von Diagrammen und einer interaktiven Karte von Deutschland.
 
Die Webanwendung bezieht die benötigten Informationen von einer (REST-)API.
Mithilfe dieser Schnittstelle kann auch ohne die Webanwendung auf Wahlinformationen zugeriffen werden.

Zusätzlich zum Abfragen von wahlbezogenen Inhalten, bietet das Wahlinformationssystem eine Benutzerschnittstelle für die Stimmabgabe.
Diese Benutzerschnittstelle unterstützt die Durchführung einer digitalen Bundestagswahl unter Berücksichtigung von Sicherheitsaspekten.

## Funktionale Anforderungen
Grundsätzlich wird die identische Funktionalität für die Bundestagswahl 2017 und die Bundestagswahl 2021 gefordert.
### Kernfunktionen
Alle relevanten Daten für die Bundestagswahlen (Bundesländer, Wahlkreise, Landeslisten, Direktkandidaturen, Kandidaten, Einzelstimmen und Parteien) müssen persistiert werden.
Dies ermöglicht einen Vergleich der Bundestagswahlen 2017 und 2021.
Eine Verwendung von personenbezogenen Daten zu den Wahlbewerberinnen und Wahlbewerbern der Bundestagswahl 2017 ist aus Gründen des Datenschutzes gemäß § 86 Absatz 3 Bundeswahlordnung nicht mehr möglich.

Ausgehend von den Einzelstimmen soll die Sitzverteilung des Bundestags nach den Bundestagswahlen 2017 und 2021 berechnet werden unter Berücksichtung von relevanten juristischen Ausnahmefälle wie der 5%-Hürde, Überhangsmandaten und Minderheitsparteien.
Die berechnete Anzahl an Mandaten pro Partei im Bundestag soll dann anschließend in der Webapplikation grafisch aufbereitet werden.
Zusätzlich sollen für die Bundestagswahl 2021 die Kandidatinnen und Kandidaten aufgelistet werden, welche tatsächlich in den Bundestag eingezogen sind.

Mit der Realisierung eines interaktiven Stimmzettels soll es möglich sein mit dem System eine elektronische Stimmabgabe für die Bundestagswahl 2021 im Wahllokal durchzuführen.
Der Stimmzettel zeigt die in einem Wahlkreis zur Wahl stehenden Direktkandidatinnen und -kandidaten an, sowie alle Parteien, welche mit einer Landesliste im entsprechenden Bundesland antreten.
Wählerinnen und Wählern muss zudem ermöglicht werden ungültig zu wählen.

### Weitere Anforderungen
- Erst- und Zweitstimmenergebnis pro Wahlkreis ausgeben und visualisieren mithilfe von Säulendiagrammen
- Heatmaps für jede Partei, die zeigen, in welchen Gebieten eine Partei bezüglich Erst- und Zweitstimmen am stärksten abgeschnitten hat
- Vergleich der Zusammensetzung des Bundestags sowie der Erst- und Zweitstimmenergebnisse auf Wahlkreisebene von 2021 gegenüber 2017
- interessante Statistiken berechnen und visualisieren:
    - knappste Siege/Niederlagen bezüglich Erststimmen in einem Wahlkreis
    - Wahlergebnis in östlichen Bundesländern
    - Anzahl an Überhangsmandaten
    - Vergleichsstatistiken basierend auf Strukturdaten der einzelnen Wahlkreise
- ausführliche Dokumentation

## Nichtfunktionale Anforderungen
- **Usability**:
    - wenige Klicks zum Ergebnis
    - einfaches Umschalten zwischen Bundestagswahlen 2017 und 2021
    - konsistente Gestaltung der Benutzerschnittstellen
- **Reliability**
    - robust gegenüber fehlerhaften Eingaben und fehlenden Berechtigungen
    - Anwendende können keine eigenen Datenbankabfragen von Wahlinformationen formulieren
- **Performance**:
	- geeignet für knapp 2*60Mio. Stimmeingaben innerhalb des Wahlzeitfensters
	- (Neu-)Berechnung der genauen Sizverteilung im Bundestag innerhalb von 5s (Speichermedium: SSD)
	- effiziente Analysen auf universellen Datenbanksystemen und Consumer-Hardware ermöglichen
    - Möglichkeit pro Wahlkreis Einzelstimmen zu Wahlkreisergebnissen vorzuaggregieren (bewusste Einführung von Redundanz)
- **Supportability**:
	- Webapplikation global erreichbar
    - bedienbar auf allen gängigen Webbrowsern

## Constraints
- Nutzung eines relationalen Datenbanksystems
- Berechnung der Zusammensetzung des Bundestags und anderer Statistiken mit SQL
- DSGVO-Konformität für Peristierung der Wahlinformationen und Stimmabgabe

## Abnahmekriterien
- korrekte Berechnung der Sitzverteilung unter Berücksichtigung relevanter Sonderregelungen
  - 5%-Hürde
  - Überhangsmandate (außer die ersten drei Überhangsmandate, welche seit der Bundestagswahl 2021 nicht mehr ausgeglichen werden)
  - nationale Minderheiten
- Stimmeingabe funktioniert und identifiziert mögliche Fehlerfälle
- direkter Vergleich der Ergebnisse der Bundestagswahl 2021 mit der Bundestagswahl 2017 möglich
- ausführliche Versionierung und Artefakte sind vorhanden
