import unittest

import psycopg

from logic.SQL_util import table_to_dict_list
from logic.config import conn_string


class TestSitzeNachErhoehungSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            conn_string,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    def test_sitze_nach_erhoehung(self):
        expected_20 = {
            'SPD': 206,
            'CDU': 152,
            'CSU': 45,
            'GRÜNE': 118,
            'FDP': 92,
            'AfD': 83,
            'DIE LINKE': 39,
            'SSW': 1
        }

        expected_19 = {
            'SPD': 153,
            'CDU': 200,
            'CSU': 46,
            'GRÜNE': 67,
            'FDP': 80,
            'AfD': 94,
            'DIE LINKE': 69
        }

        sitzverteilung = table_to_dict_list(self.cursor, 'sitzverteilung')

        actual_19 = {
            row['partei']: row['sitze'] for row in sitzverteilung if row['wahl'] == 19
        }
        actual_20 = {
            row['partei']: row['sitze'] for row in sitzverteilung if row['wahl'] == 20
        }

        self.assertEqual(actual_19, expected_19)
        self.assertEqual(actual_20, expected_20)


if __name__ == '__main__':
    unittest.main()
