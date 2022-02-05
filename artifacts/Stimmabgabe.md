# Ablauf Stimmabgabe

## Vorbereitung
- SQL-Tabelle mit Tokens (UUIDs) verknüpft mit Wahlkreis
- Wahlhelfer/autorisierte Personen erhalten (Admin-)Token für ihren Wahlkreis mit dem sich unter `/api/20/Wahlkreis/<wknr>/wahl_token`
auf Bedarf gültige (Wahl-)tokens für den Wahlkreis generieren lassen 

## Durchführung im Wahllokal
- wahlberechtigte Person besucht Wahllokal
- Identifikation mit Personalausweis (Wahlhelfer im Wahllokal führt Liste mit Personen, die schon eine Stimme abgegeben haben)
- Wahlhelfer generiert neues Wahltoken, druckt es aus, und übergibt es dem Wahlberechtigten (Wahlhelfer kann auch Tokens auf Vorrat erzeugen, um den Vorgang am Wahltag zu beschleunigen)
- Wähler betritt sichtgeschützten Bereich, der die Weboberfläche zur Stimmabgabe zeigt (/Stimmabgabe/{Wahlkreisnummer}), die bereits auf den entsprechenden Wahlkreis voreingestellt ist und einen gültigen Stimmzettel anzeigt
- Wähler setzt Kreuze (wahlweise auch ungültige Stimmen)
- Eingabe des Tokens durch Eingabefeld in Weboberfläche
- Feedback, ob Stimmabgabe erfolgreich/fehlgeschlagen
  - bei erfolgreicher Stimmabgabe:
    - die Einzelstimmen werden anonymisiert in die Datenbank eingefügt
    - das Token wird invalidiert
  - bei fehlgeschlagener Stimmabgabe:
    - mögliche Gründe für das Scheitern werden angezeigt
- bei falscher Eingabe des Tokens ist die erneute Stimmabgabe mit einem neuen Wahlzettel möglich
- nach einer erfolgreichen/fehlgeschlagenen Stimmabgabe wird nach einer festgelegten Zeitspanne (Default: 10s) ein neuer Stimmzettel geladen

## Datenschutz

Im Aspekt des Datenschutzes unterscheidet sich das vorgeschlagene Verfahren nicht ausschlaggebend vom bisherigen Wahlverfahren.
Zusätzlich zur Kontrolle des Personalausweises im Wahllokal erfordert das vorgeschlagene Verfahren die Generierung eines Tokens.
Dieser ist **NICHT** mit der wahlberechtigten Person verknüpft, sondern wird zufällig generiert.
Durch das Wählen in einem sichtgeschützten Bereich und das automatische Laden eines neuen Stimmzettels ist zudem das Wahlgeheimnis geschützt.

## Schutz vor Wahlbetrug

### Mehrfache Stimmabgabe

Ein Token ist nur für eine einzige erfolgreiche Stimmabgabe gültig. 
Durch Kontrolle des Peronalausweises kann eine Person auch nicht mehrere Tokens erhalten, da dokumentiert wird, welche Personen schon gewählt haben.
Da jedes Token nur auf Bedarf generiert wird, ist es zudem ausgeschlossen, dass eine Person bereits mit mehreren Tokens die Wahlkabine betritt.

### Stimmabgabe durch nicht autorisierte Personen

Ein Token ist nur innerhalb eines Wahlkreises gültig. 
Zudem muss die Person den Wahlhelfern im Wahllokal als wahlberechtigt bekannt sein.
Dies wird wiederum bei der Kontrolle des Personalausweises verifiziert.

### SQL-Injections

Sämtliche Nutzereingaben (auch in der URL der Weboberfläche) werden validiert (valid_... Funktionen in [util.py](../backend/logic/util.py))
bevor sie als Parameter in SQL queries/statements dienen.
