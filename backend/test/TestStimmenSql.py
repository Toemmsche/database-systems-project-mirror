import json
import unittest

import psycopg

from logic.DatabaseInitialization import db_config
from logic.util import table_to_json


class TestStimmenSql(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(
            **db_config,
            autocommit=True
        )
        self.cursor = self.conn.cursor()

    def tearDown(self):
        self.conn.close()
        self.cursor.close()

    def test_zweitstimmen_partei_wahlkreis_count(self):
        self.assertEqual(len(json.loads(table_to_json(self.cursor, 'zweitstimmen_partei_wahlkreis'))), 12728)


if __name__ == '__main__':
    unittest.main()
