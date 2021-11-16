import itertools
import uuid

import psycopg
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


def load_wahlkreise(url: str, wahl: int, deutsche_key: str, cursor: psycopg.cursor, encoding: str = 'utf-8-sig') -> None:
    records = download_csv(url, delimiter=';', skip=1, encoding=encoding)
    bundesland_mapping = key_dict(cursor, 'bundesland', ('name',), 'landId')
    records = list(
        map(
            lambda row: (
                uuid.uuid4(),
                row['Wahlkreis-Nr.'],
                row['Wahlkreis-Name'],
                bundesland_mapping[(row['Land'],)],
                wahl,
                int(parse_float_de(row[deutsche_key]) * 1000),
                None,
            ),
            filter(
                lambda row: row['Land'] != 'Deutschland' and
                            row['Wahlkreis-Name'] != 'Land insgesamt',
                records
            )
        )
    )
    load_into_db(cursor, records, 'Wahlkreis')


def load_gemeinden_2021(cursor: psycopg.cursor) -> None:
    records = local_csv(gemeinden_2021, delimiter=';')
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
    load_into_db(cursor, records, 'Gemeinde')


def load_parteien(cursor: psycopg.cursor) -> None:
    records = local_csv(parteien)
    id_iter = itertools.count()
    records = list(
        map(
            lambda row: (
                next(id_iter),
                row['Name'],
                row['Kurzbezeichnung'],
                0,  # TODO
                notFalsy(row['Gründungsdatum'][-4:], None),
                None,  # TODO
                None
            ),
            records,
        )
    )
    load_into_db(cursor, records, 'Partei')


def load_kandidaten_2021(cursor: psycopg.cursor) -> None:
    records = local_csv(kandidaten_2021, delimiter=';')

    gemeinde_mapping = key_dict(cursor, 'gemeinde', ('plz',), 'gemeindeid')

    # make candidates unique
    unique_set = set()
    temp_records = []
    for kand in records:
        key = (
            kand['Vornamen'],
            kand['Nachname'],
            kand['Geburtsjahr'],
            kand['Geburtsort'],
        )
        if key not in unique_set:
            temp_records.append(kand)
            unique_set.add(key)
    records = temp_records

    id_iter = itertools.count()
    records = list(
        map(
            lambda row: (
                next(id_iter),
                row['Vornamen'],
                row['Nachname'],
                row['Titel'],
                row['Namenszusatz'],
                row['Geburtsjahr'],
                row['Geburtsort'],
                # gemeinde_mapping[row['PLZ']],
                None,  # TODO
                row['Beruf'],
                row['Geschlecht'],
            ),
            records,
        )
    )
    load_into_db(cursor, records, 'Kandidat')


if __name__ == '__main__':
    load_gemeinden_2021(None)
