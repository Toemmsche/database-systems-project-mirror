from psycopg.types import datetime
from svgpathtools import svg2paths2

from logic.links import *
from logic.metrics import *
from logic.util import *


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
                row['id']),
            records,
        )
    )
    load_into_db(cursor, records, 'Bundesland')


def load_wahlkreise(
        url: str,
        wahl: int,
        deutsche_key: str,
        begrenzungen_url: str,
        begrenzungen_dict: dict[int, int],
        cursor: psycopg.cursor,
        encoding: str = 'utf-8-sig'
) -> None:
    records = download_csv(url, delimiter=';', skip=1, encoding=encoding)
    bundesland_mapping = key_dict(cursor, 'bundesland', ('name',), 'landId')
    ergebnisse = download_csv(ergebnisse_2021 if wahl == 20 else ergebnisse_2017, delimiter=';', skip=9)
    _, attributes, _ = svg2paths2(begrenzungen_url)

    filtered_wahlkreise = list(
        filter(
            lambda row: row['Land'] != 'Deutschland' and
                        row['Wahlkreis-Name'] != 'Land insgesamt',
            records
        )
    )

    wahlberechtigte = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'System-Gruppe' and
                        row['Gruppenname'] == 'Wahlberechtigte' and
                        row['Anzahl'] != '',
            ergebnisse
        )
    )

    wahlberechtigte_dict = {
        int(wb['Gebietsnummer']): wb['Anzahl']
        for wb in wahlberechtigte
    }

    records = list(
        map(
            lambda row: (
                row['Wahlkreis-Nr.'],
                row['Wahlkreis-Name'],
                bundesland_mapping[(row['Land'],)],
                wahl,
                int(wahlberechtigte_dict[int(row['Wahlkreis-Nr.'])]),
                attributes[begrenzungen_dict[int(row['Wahlkreis-Nr.'])]]['d'].strip().replace(',', ' '),
            ),
            filtered_wahlkreise
        )
    )
    load_into_db(cursor, records, 'Wahlkreis')

    wahlkreis_dict = key_dict(cursor, 'Wahlkreis', ('wahl', 'nummer'), 'wkid')
    struct_data_records = list(
        map(
            lambda row:
            tuple(
                [wahlkreis_dict[(wahl, int(row['Wahlkreis-Nr.']))]] +
                [parse_float_de(row[value[wahl]]) if wahl in value else None for value in sd_mapping.values()]
            ),
            filtered_wahlkreise
        )
    )
    load_into_db(cursor, struct_data_records, 'strukturdaten')


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
                False,  # No einzelbewerbung
                row['Name'],
                row['Kurzbezeichnung'],
                row['Kurzbezeichnung'] in nationale_minderheiten,
                notFalsy(row['Gründungsdatum'][-4:], None),
                parteifarben_dict[row['Kurzbezeichnung']] if row['Kurzbezeichnung'] in parteifarben_dict else 'DDDDDD'
            ),
            records,
        )
    )
    load_into_db(cursor, records, 'Partei')
