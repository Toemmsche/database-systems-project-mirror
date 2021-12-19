DROP VIEW IF EXISTS zweitstimmen_qpartei_osten CASCADE;

CREATE VIEW zweitstimmen_qpartei_osten(wahl, partei, partei_farbe, abs_stimmen) AS
    WITH nicht_qpartei(wahl, partei) AS
             (SELECT btw.nummer, p.parteiid
              FROM partei p,
                   bundestagswahl btw
              EXCEPT
              SELECT *
              FROM qpartei)
    SELECT zpb.wahl,
           p.kuerzel,
           p.farbe,
           zpb.anzahlstimmen
    FROM zweitstimmen_qpartei_bundesland zpb,
         partei p,
         bundesland bl
    WHERE zpb.partei = p.parteiid
      AND zpb.land = bl.landid
      AND bl.osten
    UNION
    SELECT zpb.wahl,
           'Sonstige',
           'DDDDDD',
           SUM(zpb.anzahlstimmen)
    FROM zweitstimmen_partei_bundesland zpb,
         partei p,
         nicht_qpartei np,
         bundesland bl
    WHERE zpb.partei = p.parteiid
      AND zpb.partei = np.partei
      AND zpb.land = bl.landid
      AND bl.osten
    GROUP BY zpb.wahl;