import json
import unittest

import psycopg

from logic.DatabaseInitialization import db_config
from logic.util import table_to_json


class TestSitzeNachErhoehungSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            **db_config,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    def test_sitze_nach_erhoehung(self):
        expected_19 = 709
        expected_20 = 736

        table = json.loads(table_to_json(self.cursor, 'sitzverteilung'))
        sum_19 = 0
        sum_20 = 0
        for row in table:
            if row['wahl'] == 19:
                sum_19 += row['sitze']
            elif row['wahl'] == 20:
                sum_20 += row['sitze']
            else:
                self.fail(f"Unexpected key for 'wahl': {row['wahl']}")
        self.assertEqual(sum_20, expected_20)
        self.assertEqual(sum_19, expected_19)


if __name__ == '__main__':
    unittest.main()
