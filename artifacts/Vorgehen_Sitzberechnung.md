# Berechnung der Sitzverteilung

## Vorgehensweise
Die Implementierung der Berechnung der Sitzverteilung folgt grob den folgenden Schritten. 

1. Berechnung von Hilfsrelationen
   1. Direktmandatsgewinner
   2. Parteien nach 5%-Hürde (und Sonderregeln) filtern
   3. Zweitstimmen pro Bundesland (und Partei)
3. Verteilung der 598 Sitze auf die Bundesländer nach deutscher Bevölkerung (**Divisorverfahren**)
4. Verteilung der Sitze innerhalb jedes Bundeslands an die Parteien basierend auf Zweitstimmen (**Divisorverfahren**)
5. Sitzkontingent und Mindesitzanspruch jeder Partei (in jedem Bundesland)
6. finale Sitzverteilung im Bundestag nach Partei (**Divisorverfahren**)
7. Sitzverteilung auf die Landeslisten jeder Partei (**Divisorverfahren**)
8. Listenmandate (abzüglich von Direktmandaten)

## Divisorverfahren
Für die Verteilung von einer festen Anzahl vorhandener Sitze auf eine Menge von Parteien oder Bundesländern basierend auf Einwohnerzahlen oder der Anzahl an Stimmen wird das **iterative Divisorverfahren** verwendet.
Das iterative Divisorverfahren kommt auch bei der [hier](https://www.bundeswahlleiter.de/dam/jcr/bf33c285-ee92-455a-a9c3-8d4e3a1ee4b4/btw21_sitzberechnung.pdf) dokumentierten Berechnung zum Einsatz.
Da dieses Verfahren während der Ermittlung der Sitzverteilung mehrfach zum Einsatz kommt, existiert für diese Berechnung eine SQL-Funktion mit dem Namen ```divisorverfahren```.
Das iterative Divisorverfahren terminiert in der Regel nach wenigen Iterationen, da sich die Anzahl der Sitze mit jeder Iteration um eins der vorgegebenen Anzahl nähert.

## Erklärung der CTEs
Die in SQL realisierte Berechnung der Sitzverteilung verwendet eine Vielzahl von (rekursiven) CTEs, 

| CTE                                        | Spalten                                                                                 | Beschreibung                                                                                                                                                                                                            |
|--------------------------------------------|-----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| direktkandidatur_nummeriert                | (wahlkreis, partei, kandidatur, kandidat, wk_rang)                                      | Direktkandidaturen mit Rang in ihrem Wahlkreis                                                                                                                                                                          |
| direktmandat                               | (wahl, land, partei, wahlkreis, kandidatur, kandidat)                                   | Gewinner von Direktmandaten                                                                                                                                                                                             |
| zweitstimmen_partei_wahlkreis              | (wahl, wahlkreis, partei, anzahlstimmen)                                                | Zweitstimmen pro Wahl, Partei und Wahlkreis                                                                                                                                                                             |
| zweitstimmen_partei_bundesland             | (wahl, land, partei, anzahlstimmen)                                                     | Zweitstimmen pro Wahl, Bundesland und Partei                                                                                                                                                                            |
| zweitstimmen_partei                        | (wahl, partei, anzahlstimmen)                                                           | Zweitstimmen pro Wahl und Partei                                                                                                                                                                                        |
| zweitstimmen                               | (wahl, anzahlstimmen)                                                                   | Zweitstimmen pro Wahl                                                                                                                                                                                                   |
| qpartei                                    | (wahl, partei)                                                                          | qualifizierte (>= 5% der bundesweiten, gültigen Zweitstimmen Parteien oder >= 3 Direktmandate oder nationale Minderheit) Parteien                                                                                       |
| zweitstimmen_qpartei_bundesland            | (wahl, land, partei, anzahlstimmen)                                                     | Zweitstimmen pro Wahl, Bundesland und Partei (nur für qualifizierte Parteien)                                                                                                                                           |
| zweitstimmen_qpartei                       | (wahl, partei, anzahlstimmen)                                                           | Zweitstimmen pro Wahl und Partei (nur für qualifizierte Parteien)                                                                                                                                                       |
| direktmandate_qpartei_bundesland           | (wahl, land, partei, direktmandate)                                                     | Anzahl von Direktmandaten pro Wahl, Partei und Bundesland (nur für qualifizierte Parteien)                                                                                                                              |
| gesamtsitze                                | (wahl, anzahlsitze)                                                                     | Startwert für Anzahl der Sitze im Bundestag                                                                                                                                                                             |
| bundesland_bevoelkerung                    | (wahl, land, bevoelkerung)                                                              | deutsche Bevölkerung pro Bundesland und Wahl (stimmt nicht mit der Anzahl der Wahlberechtigten oder dem Wert von den Strukturdaten überein)                                                                             |
| divisor_kandidat                           | (divisor)                                                                               | für das iterative Divisorverfahren verwendete Werte, um mögliche Divisorkandidaten zu ermitteln (später Sitzanzahl +/-0,5)                                                                                              |
| bund_divisor                               | (wahl, divisor)                                                                         | Divisor, mit welchem die anfänglichen 598 Sitze auf die Bundesländer aufgeteilt werden                                                                                                                                  |
| sitze_bundesland                           | (wahl, divisor)                                                                         | Anzahl der Sitze für jedes Bundesland berechnet mit dem Divisor von ```bund_divisor```                                                                                                                                  |
| laender_divisor                            | (wahl, land, divisor)                                                                   | Divisor für jedes Bundesland, mit welchem die mit ```sitze_bundesland``` berechneten Sitze pro Bundesland auf die Parteien aufgeteilt werden                                                                            |
| sitzkontingent_qpartei_bundesland          | (wahl, land, partei, sitzkontingent)                                                    | Anzahl der Sitze für Parteien in jedem Bundesland berechnet mit den Divisoren von ```laender_divisor```                                                                                                                 |
| mindestsitze_qpartei_bundesland            | (wahl, land, partei, sitzkontingent, direktmandate, mindestsitze, ueberhang)            | Mindestanzahl der Sitze für Parteien in jedem Bundesland basierend auf den Berechnungen von ```sitzkontingent_qpartei_bundesland``` und der Anzahl gewonnener Direktmandate inklusive dem dadurch entstehenden Überhang |
| sitzanspruch_qpartei                       | (wahl, partei, sitzkontingent, mindestsitzanspruch, drohender_ueberhang, anzahlstimmen) | Mindestanzahl der Sitze für Parteien basierend auf den Mindestsitzanzahlen der einzelnen Länder inklusive dem dadurch entstehenden Überhang                                                                             |
| divisor_obergrenze                         | (wahl, obergrenze)                                                                      | Obergrenze für den Divisor, aus welchem hervorgeht wie viele Stimmen für ein Mandat erforderlich sind unter Berücksichtigung des Überhangs                                                                              |
| divisor_untergrenze                        | (wahl, untergrenze)                                                                     | Untergrenze für den Divisor, aus welchem hervorgeht wie viele Stimmen für ein Mandat erforderlich sind unter Berücksichtigung des Überhangs                                                                             |
| endgueltiger_divisor                       | (wahl, divisor)                                                                         | endgültiger Divisor, aus welchem hervorgeht wie viele Stimmen für ein Mandat erforderlich sind unter Berücksichtigung des Überhangs als Mittelwert der Ober- und Untergrenze                                            |
| sitze_nach_erhoehung                       | (wahl, partei, sitze)                                                                   | Anzahl der Sitze für Parteien berechnet mit dem endgültigen Divisor unter Berücksichtigung der bereits berechneten Mindestsitzzahl                                                                                      |
| landeslisten_divisor                       | (wahl, partei, sitze_ll_sum, divisor, next_divisor)                                     | Divisor für jedes Bundesland und jede Partei, mit welchem die mit ```sitze_nach_erhoehung``` berechneten Sitze pro Partei auf die Bundesländer aufgeteilt werden                                                        |
| sitze_landesliste                          | (wahl, partei, land, sitze_ll)                                                          | Anzahl der Sitze pro Land für jede Partei berechnet mit den Divisoren von ```landeslisten_divisor``` basierend auf der Sitzanzahl nach Erhöhung und der Mindestsitzanzahl                                               |
| verbleibende_sitze_landesliste             | (wahl, partei, land, verbleibende_sitze)                                                | Anzahl der Sitze pro Land für jede Partei, die nicht von Direktmandaten belegt werden                                                                                                                                   |
| landeslisten_ohne_direktmandate            | (wahl, liste, partei, land, position, kandidat)                                         | Landeslisten ohne Kandidaten, die durch ein Direktmandat bereits direkt in den Bundestag einziehen (kann nur für 2021 ermittelt werden)                                                                                 |
| landeslisten_ohne_direktmandate_nummeriert | (wahl, liste, partei, land, position, kandidat, neue_position)                          | Landeslisten mit aktualisierten Listenplätzen nach dem Entfernen der Gewinner eines Direktmandats                                                                                                                       |
| listenmandat                               | (wahl, land, partei, liste, position, kandidat)                                         | Alle Kandidaten, die über die Landeslisten einen Platz im Bundestag erhalten                                                                                                                                            |

## 2017 vs. 2021
Die Berechnung wird für beide Wahlen "parallel" mit den gleichen CTEs durchgeführt.
Aus diesem Grund besitzen nahezu alle CTEs ein Attribut ```wahl```.
Um die leicht unterschiedlichen Berechnungen der Sitzverteilung für 2017 und 2021 trotzdem unterstützen zu können, enthält die Implementierung einige Fallunterscheidungen.

### Berechnung der Mindestsitzanzahl für Parteien in Bundesländern
In 2017 wird die Mindestsitzzahl als das Maximum aus Direktmandate und Sitzkontingente gebildet.
In 2021 wird die Mindestsitzzahl als Durchschnitt aus Direktmandate und Sitzkontingente gebildet.

### Ausgleich von Überhangsmandaten
In 2017 werden alle Überhangsmandate ausgeglichen.
In 2021 werden die ersten drei Überhangsmandate NICHT ausgeglichen und es wird mit dem Mindestsitzanspruch gerechnet.

### Berechnung der Divisoren für Landeslisten
In 2017 muss bei der Berechnung der CTE ```landeslisten_divisor``` die Anzahl der gewonnen Direktmandate berücksichtigt werden
In 2021 muss bei der Berechnung der CTE ```landeslisten_divisor``` die Anzahl der Mindestsitze berücksichtigt werden.

### Landesliten ohne Direktmandate
In 2017 können die Landeslisten ohne direktmandate nicht ermittelt werden, da keine personenbezogene Daten vorliegen.
In 2021 können die Landeslisten ohne direktmandate ermittelt werden.
