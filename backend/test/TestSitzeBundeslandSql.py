import json
import unittest

import psycopg

from logic.DatabaseInitialization import db_config
from logic.util import table_to_json


class TestSitzeBundeslandSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            **db_config,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    def test_sitze_bundesland_2021(self):
        expected = {
            1: 22,
            13: 13,
            2: 13,
            3: 59,
            4: 5,
            12: 20,
            15: 17,
            11: 24,
            5: 127,
            14: 32,
            6: 43,
            16: 16,
            7: 30,
            9: 93,
            8: 77,
            10: 7
        }
        table = json.loads(table_to_json(self.cursor, 'sitze_bundesland'))
        for row in table:
            if row['wahl'] == 20:
                self.assertEqual(row['sitze'], expected[row['land']])


if __name__ == '__main__':
    unittest.main()
