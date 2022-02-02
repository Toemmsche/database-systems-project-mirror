import unittest

import psycopg

from logic.config import conn_string
from logic.links import ergebnisse_2021, ergebnisse_2017
from logic.util import query_to_dict_list, download_csv


class TestAnzahlStimmenSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            conn_string,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    def test_gesamt_erststimmen(self):
        expected_19 = 46389615
        expected_20 = 46362013

        query = f"""
        SELECT wk.wahl, SUM(dk.anzahlstimmen) as summe_stimmen
        FROM wahlkreis wk,
            direktkandidatur dk
        WHERE wk.wkid = dk.wahlkreis
        GROUP BY wk.wahl
        """

        res_list = query_to_dict_list(self.cursor, query)
        actual_20 = next(row for row in res_list if row['wahl'] == 20)['summe_stimmen']
        actual_19 = next(row for row in res_list if row['wahl'] == 19)['summe_stimmen']

        self.assertEqual(actual_20, expected_20)
        self.assertEqual(actual_19, expected_19)

    def test_row_by_row_erststimme_2021(self):
        for wahl in (19, 20):
            ergebnisse = download_csv(ergebnisse_2021 if wahl == 20 else ergebnisse_2017, delimiter=';', skip=9)
            ergebnisse_wahlkreis = list(
                filter(
                    lambda row: row['Gebietsart'] == 'Wahlkreis' and
                                row['Gruppenart'] != 'System-Gruppe' and
                                row['Stimme'] == '1' and
                                row['Anzahl'] != '',
                    ergebnisse
                )
            )

            query = f"""
                   SELECT wk.nummer, p.name, p.kuerzel, p.ist_einzelbewerbung, SUM(dk.anzahlstimmen) AS anzahlstimmen
                   FROM wahlkreis wk,
                       direktkandidatur dk,
                       partei p
                   WHERE wk.wkid = dk.wahlkreis
                       AND dk.partei = p.parteiid
                       AND wk.wahl = {wahl}
                   GROUP BY wk.nummer, p.kuerzel, p.name, p.ist_einzelbewerbung
                   order by wk.nummer
                   """
            res_list = query_to_dict_list(self.cursor, query)

            wahlkreis_kuerzel_dict = {
                (row['nummer'], row['kuerzel']): row['anzahlstimmen']
                for row in res_list
            }

            wahlkreis_name_dict = {
                (row['nummer'], row['name']): row['anzahlstimmen']
                for row in res_list
            }

            expected_sum = 0
            actual_sum = 0

            for row in ergebnisse_wahlkreis:
                wk_nummer = int(row['Gebietsnummer'])
                partei = row['Gruppenname'] if wahl == 20 or row[
                    'Gruppenart'] != 'Einzelbewerber/Wählergruppe' else f"WK-{int(row['Gebietsnummer'])}-{row['Gruppenname']}"

                # Veränderte parteinamen
                if wahl == 19:
                    if partei == 'Neue Liberale':
                        partei = 'SL'
                    elif partei == 'MG':
                        partei = 'Gartenpartei'

                expected_anzahl = int(row['Anzahl'])
                expected_sum += expected_anzahl

                wk_partei_tupel = (wk_nummer, partei)
                if row['Gruppenart'] == 'Einzelbewerber/Wählergruppe':
                    if wk_partei_tupel in wahlkreis_name_dict:
                        actual_anzahl = wahlkreis_name_dict[wk_partei_tupel]
                        actual_sum += actual_anzahl

                        self.assertEqual(expected_anzahl, actual_anzahl)

                        # remove processed party
                        wahlkreis_name_dict.pop(wk_partei_tupel)
                        continue
                if wk_partei_tupel not in wahlkreis_kuerzel_dict:
                    self.fail(f"Cannot find {wk_partei_tupel}")
                else:
                    actual_anzahl = wahlkreis_kuerzel_dict[wk_partei_tupel]
                    actual_sum += actual_anzahl

                    self.assertEqual(expected_anzahl, actual_anzahl)

                    # remove processed party
                    wahlkreis_kuerzel_dict.pop(wk_partei_tupel)

            self.assertEqual(expected_sum, actual_sum)


if __name__ == '__main__':
    unittest.main()
