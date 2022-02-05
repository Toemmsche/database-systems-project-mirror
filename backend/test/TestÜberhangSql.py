import unittest

import psycopg

from logic.SQL_util import table_to_dict_list, query_to_dict_list
from logic.config import conn_string


class TestÜberhangSql(unittest.TestCase):

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
            'SPD': 10,
            'CDU': 12,
            'CSU': 11,
            'AfD': 1,
        }

        expected_19 = {
            'SPD': 3,
            'CDU': 36,
            'CSU': 7,
        }

        query=f"""
        SELECT u.wahl, u.partei, SUM(u.ueberhang) as ueberhang
        FROM ueberhang_qpartei_bundesland u
        GROUP BY u.wahl, u.partei
        """

        ueberhang_aggregiert = query_to_dict_list(self.cursor, query)

        actual_19 = {
            row['partei']: row['ueberhang'] for row in ueberhang_aggregiert if row['wahl'] == 19
        }
        actual_20 = {
            row['partei']: row['ueberhang'] for row in ueberhang_aggregiert if row['wahl'] == 20
        }

        self.assertEqual(actual_19, expected_19)
        self.assertEqual(actual_20, expected_20)


if __name__ == '__main__':
    unittest.main()
