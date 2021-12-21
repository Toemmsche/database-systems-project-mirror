DROP VIEW IF EXISTS zweitstimmen_qpartei_osten CASCADE;

CREATE VIEW zweitstimmen_qpartei_osten(wahl, partei, partei_farbe, abs_stimmen, rel_stimmen) AS
    WITH zweitstimmen_partei_osten(wahl, partei, anzahlstimmen) AS
             (SELECT ll.wahl, ll.partei, SUM(ze.anzahlstimmen)
              FROM bundesland bl,
                   zweitstimmenergebnis ze,
                   landesliste ll
              WHERE ze.liste = ll.listenid
                AND bl.landid = ll.land
                AND bl.osten
              GROUP BY ll.wahl, ll.partei),
         zweitstimmen_osten(wahl, anzahlstimmen) AS
             (SELECT zpo.wahl, SUM(zpo.anzahlstimmen)
              FROM zweitstimmen_partei_osten zpo
              GROUP BY zpo.wahl),
         zweitstimmen_partei_osten_rel(wahl, partei, abs_stimmen, rel_stimmen) AS
             (SELECT zpo.*, zpo.anzahlstimmen::decimal / zo.anzahlstimmen
              FROM zweitstimmen_partei_osten zpo,
                   zweitstimmen_osten zo
              WHERE zpo.wahl = zo.wahl)
    SELECT zpo.wahl,
           p.kuerzel,
           p.farbe,
           zpo.abs_stimmen,
           zpo.rel_stimmen
    FROM zweitstimmen_partei_osten_rel zpo,
         partei p
    WHERE zpo.partei = p.parteiid
      AND zpo.rel_stimmen >= 0.05
    UNION
    SELECT zpo.wahl,
           'Sonstige',
           'DDDDDD',
           SUM(zpo.abs_stimmen),
           SUM(zpo.rel_stimmen)
    FROM zweitstimmen_partei_osten_rel zpo,
         partei p
    WHERE zpo.partei = p.parteiid
      AND zpo.rel_stimmen < 0.05
    GROUP BY zpo.wahl;