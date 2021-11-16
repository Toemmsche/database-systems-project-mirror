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


def load_wahlkreise(cursor: psycopg.cursor) -> None:
    records = download_csv(wahlkreise_2021, delimiter=';', skip=1)
    bundesland_mapping = key_dict(cursor, 'bundesland', ('name',), 'landId')
    id_iter = itertools.count()
    records = list(
        map(
            lambda row: (
                next(id_iter),
                row['Wahlkreis-Nr.'],
                row['Wahlkreis-Name'],
                bundesland_mapping[(row['Land'],)],
                20,
                0,
                None,
            ),
            filter(
                lambda row: row['Land'] != 'Deutschland' and
                            row['Wahlkreis-Name'] != 'Land insgesamt',
                records
            )
        )
    )
    print(records[290:])
    load_into_db(cursor, records, 'Wahlkreis')


def load_gemeinden(cursor: psycopg.cursor) -> None:
    records = local_csv(gemeinden, delimiter=';')
    wk_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl'), 'wkid')
    id_iter = itertools.count()
    records = list(
        map(
            lambda row: (next(id_iter),
                         row['Gemeindename'],
                         row['PLZ-GemVerwaltung'],
                         wk_mapping[(int(row['Wahlkreis-Nr']), 20)],
                         None),
            records,
        )
    )
    records = list(set(records))
    load_into_db(cursor, records, 'Gemeinde')


if __name__ == '__main__':
    load_gemeinden(None)
