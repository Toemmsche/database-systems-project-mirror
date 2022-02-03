import unittest

import psycopg

from logic.SQL_util import table_to_dict_list
from logic.config import conn_string
from logic.links import mdb_2021
from logic.util import local_csv


class TestMdbSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            conn_string,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    # test only feasible for 2021
    def test_mandate_2021(self):
        mdb_expected = local_csv(mdb_2021, delimiter=';')

        # The bottom 4 candidates are 'nachrücker', we disregard them
        mdb_expected = mdb_expected[:-4]

        res_list = table_to_dict_list(self.cursor, 'mitglieder_bundestag', wahl=20)

        mdb_actual = set(
            [(row['vorname'], row['nachname'], row['geburtsjahr'], row['partei'], row['grund'].startswith('Direktmandat')) for row in
             res_list])

        self.assertEqual(len(mdb_expected), len(mdb_actual))
        for row in mdb_expected:
            key = (
                row['Vornamen'], row['Nachname'], int(row['Geburtsjahr']), row['Gruppenname'], row['Kennzeichen'] == 'Kreiswahlvorschlag')
            if key not in mdb_actual:
                self.fail(f"Cannot find {key}")


if __name__ == '__main__':
    unittest.main()
