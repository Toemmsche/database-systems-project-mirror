DROP VIEW IF EXISTS zweitstimmen_partei_osten CASCADE;

CREATE VIEW zweitstimmen_partei_osten(wahl, ist_osten, partei, partei_farbe, abs_stimmen, rel_stimmen) AS
    WITH zweitstimmen_partei(wahl, ist_osten, partei, anzahlstimmen) AS
             (SELECT ll.wahl, bl.osten, ll.partei, SUM(ze.anzahlstimmen)
              FROM bundesland bl,
                   zweitstimmenergebnis ze,
                   landesliste ll
              WHERE ze.liste = ll.listenid
                AND bl.landid = ll.land
              GROUP BY ll.wahl, bl.osten, ll.partei),
         zweitstimmen_osten(wahl, ist_osten, anzahlstimmen) AS
             (SELECT zp.wahl, zp.ist_osten, SUM(zp.anzahlstimmen)
              FROM zweitstimmen_partei zp
              GROUP BY zp.wahl, zp.ist_osten),
         zweitstimmen_partei_osten_rel(wahl, ist_osten, partei, abs_stimmen, rel_stimmen) AS
             (SELECT zp.*, zp.anzahlstimmen::DECIMAL / zo.anzahlstimmen
              FROM zweitstimmen_partei zp,
                   zweitstimmen_osten zo
              WHERE zp.wahl = zo.wahl
                AND zp.ist_osten = zo.ist_osten),
         partei_filtered
             (wahl, partei, ist_einzug)
             AS
             (SELECT zpo.wahl,
                     zpo.partei,
                     BOOL_OR(zpo.rel_stimmen >= 0.022) --Hürde ist niedriger als 5%, damit auch Randparteien erscheinen
              FROM zweitstimmen_partei_osten_rel zpo
              GROUP BY zpo.wahl, zpo.partei)
    SELECT zpo.wahl,
           zpo.ist_osten,
           p.kuerzel,
           p.farbe,
           zpo.abs_stimmen,
           zpo.rel_stimmen
    FROM zweitstimmen_partei_osten_rel zpo,
         partei_filtered pf,
         partei p
    WHERE zpo.wahl = pf.wahl
      AND zpo.partei = p.parteiid
      AND zpo.partei = pf.partei
      AND pf.ist_einzug
    UNION
    SELECT zpo.wahl,
           zpo.ist_osten,
           'Sonstige',
           'DDDDDD',
           SUM(zpo.abs_stimmen),
           SUM(zpo.rel_stimmen)
    FROM zweitstimmen_partei_osten_rel zpo,
         partei p,
         partei_filtered pf
    WHERE zpo.wahl = pf.wahl
      AND zpo.partei = p.parteiid
      AND zpo.partei = pf.partei
      AND NOT pf.ist_einzug
    GROUP BY zpo.wahl, zpo.ist_osten;