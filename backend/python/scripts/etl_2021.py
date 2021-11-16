import itertools

from psycopg.types import datetime
from util import *
from links import *


def load_bundestagswahl_2021(cursor: psycopg.cursor):
    load_into_db(
        cursor,
        [
            (19, datetime.date(2017, 9, 24)),
            (20, datetime.date(2021, 9, 26)),
        ],
        'Bundestagswahl'
    )


def load_bundeslaender(cursor: psycopg.cursor) -> None:
    records = download_csv(bundeslaender)
    records = list(
        map(
            lambda row: (row['label'], row['name_de'], 0, None),
            records,
        )
    )
    load_into_db(cursor, records, 'Bundesland')


def load_gemeinden(cursor: psycopg.cursor) -> None:
    records = local_csv(gemeinden, delimiter=';')
    records = list(
        map(
            lambda row: (itertools.count.next,
                         row['Gemeindename'],
                         row['PLZ-GemVerwaltung'],
                         row['Wahlkreis-Nr'],
                         None),
            records,
        )
    )
    load_into_db(cursor, records, 'Gemeinde')


if __name__ == '__main__':
    load_gemeinden(None)
