from logic.links import *
from logic.util import *
from psycopg.types import datetime
from svgpathtools import svg2paths2


def load_bundestagswahl(cursor: psycopg.cursor):
    load_into_db(
        cursor,
        [
            (datetime.date(2017, 9, 24), 19),
            (datetime.date(2021, 9, 26), 20),
        ],
        'Bundestagswahl'
    )


def load_bundeslaender(cursor: psycopg.cursor) -> None:
    records = download_csv(bundeslaender)
    osten_bundeslaender = ['BB', 'SN', 'MV', 'TH', 'ST']  # no berlin
    records = list(
        map(
            lambda row: (
                row['label'],
                row['name_de'],
                row['label'] in osten_bundeslaender,  # osten
                None,
                row['id']),
            records,
        )
    )
    load_into_db(cursor, records, 'Bundesland')


def load_wahlkreise(
        url: str, wahl: int, deutsche_key: str, begrenzungen_url: str, begrenzungen_dict: dict[int, int],
        cursor: psycopg.cursor,
        encoding: str = 'utf-8-sig'
) -> None:
    records = download_csv(url, delimiter=';', skip=1, encoding=encoding)
    bundesland_mapping = key_dict(cursor, 'bundesland', ('name',), 'landId')
    _, attributes, _ = svg2paths2(begrenzungen_url)

    records = list(
        map(
            lambda row: (
                row['Wahlkreis-Nr.'],
                row['Wahlkreis-Name'],
                bundesland_mapping[(row['Land'],)],
                wahl,
                int(parse_float_de(row[deutsche_key]) * 1000),
                attributes[begrenzungen_dict[int(row['Wahlkreis-Nr.'])]]['d'].strip().replace(',', ' ')
            ),
            filter(
                lambda row: row['Land'] != 'Deutschland' and
                            row['Wahlkreis-Name'] != 'Land insgesamt',
                records
            )
        )
    )
    load_into_db(cursor, records, 'Wahlkreis')


def load_gemeinden(
        url: str,
        wahl: int,
        cursor: psycopg.cursor,
        encoding: str = 'utf-8-sig'
) -> None:
    records = local_csv(url, delimiter=';', encoding=encoding)
    wk_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl'), 'wkid')
    records = list(
        map(
            lambda row: (
                row['Gemeindename'],
                row['PLZ-GemVerwaltung'],
                wk_mapping[(int(row['Wahlkreis-Nr']), wahl)],
                None),
            records,
        )
    )
    load_into_db(cursor, records, 'Gemeinde')


def load_parteien(cursor: psycopg.cursor) -> None:
    parteifarben_dict = {
        'CDU': '000000',
        'SPD': 'EB001F',
        'AfD': '00ADEF',
        'CSU': '0077B3',
        'FDP': 'FFED00',
        'DIE LINKE': 'BE3075',
        'GRÜNE': '64A12D'
    }

    nationale_minderheiten = {'SSW'}

    records = local_csv(parteien)
    records = list(
        map(
            lambda row: (
                row['Name'],
                row['Kurzbezeichnung'],
                row['Kurzbezeichnung'] in nationale_minderheiten,
                notFalsy(row['Gründungsdatum'][-4:], None),
                parteifarben_dict[row['Kurzbezeichnung']] if row['Kurzbezeichnung'] in parteifarben_dict else 'DDDDDD',
                None
            ),
            records,
        )
    )
    load_into_db(cursor, records, 'Partei')
