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


def load_wahlkreise(url: str, wahl: int, deutsche_key: str, cursor: psycopg.cursor,
                    encoding: str = 'utf-8-sig') -> None:
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


def load_gemeinden(url: str, wahl: int, cursor: psycopg.cursor, encoding: str = 'utf-8-sig') -> None:
    records = local_csv(url, delimiter=';', encoding=encoding)
    wk_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl'), 'wkid')
    records = list(
        map(
            lambda row: (
                uuid.uuid4(),
                row['Gemeindename'],
                row['PLZ-GemVerwaltung'],
                wk_mapping[(int(row['Wahlkreis-Nr']), wahl)],
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
    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    partei_mapping = {(x[0].upper(),): partei_mapping[x] for x in partei_mapping}
    wahlkreis_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl',), 'wkId')

    # make candidates unique
    unique_set = set()
    temp_records = []
    for kand in records:
        kand['kandId'] = uuid.uuid4()
        key = (
            kand['Vornamen'],
            kand['Nachname'],
            kand['Geburtsjahr'],
            # kand['Geburtsort'], different birthplace format for Mr. Traymont Wilhelmi
        )
        if key not in unique_set:
            temp_records.append(kand)
            unique_set.add(key)
    records = temp_records

    kandidaten_landesliste_1 = list(
        filter(
            lambda row: row['Kennzeichen'] == 'Landesliste',
            records
        )
    )
    kandidaten_landesliste_2 = list(
        filter(
            lambda row: row['VerknKennzeichen'] == 'Landesliste',
            records
        )
    )

    direktkandidaten = list(
        filter(
            lambda row: row['Kennzeichen'] == 'Kreiswahlvorschlag',
            records
        )
    )

    direktkandidaten_parteilos = list(
        filter(
            lambda row: row['Kennzeichen'] == 'anderer Kreiswahlvorschlag',
            records
        )
    )

    unique_landeslisten = dict()
    landeslisten = list()
    for kand in kandidaten_landesliste_1:
        key = (
            kand['GebietLandAbk'],
            kand['Gruppenname']
        )
        if key not in unique_landeslisten:
            landeslisten.append(key)
            unique_landeslisten[key] = uuid.uuid4()

    for kand in kandidaten_landesliste_2:
        key = (
            kand['VerknGebietLandAbk'],
            kand['VerknGruppenname']
        )
        if key not in unique_landeslisten:
            landeslisten.append(key)
            unique_landeslisten[key] = uuid.uuid4()

    landeslisten = list(
        map(
            lambda liste: (
                unique_landeslisten[liste],
                partei_mapping[(liste[1].upper(),)],
                20,
                liste[0],
                0 # TODO: Stimmzettelposition
            ),
            landeslisten
        )
    )
    load_into_db(cursor, landeslisten, 'Landesliste')

    records = list(
        map(
            lambda row: (
                row['kandId'],
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

    kandidaten_landesliste_1 = list(
        map(
            lambda row: (
                row['Listenplatz'],
                row['kandId'],
                unique_landeslisten[(row['GebietLandAbk'], row['Gruppenname'])]
            ),
            kandidaten_landesliste_1
        )
    )
    kandidaten_landesliste_2 = list(
        map(
            lambda row: (
                row['VerknListenplatz'],
                row['kandId'],
                unique_landeslisten[(row['VerknGebietLandAbk'], row['VerknGruppenname'])]
            ),
            kandidaten_landesliste_2
        )
    )
    load_into_db(cursor, kandidaten_landesliste_1 + kandidaten_landesliste_2, 'Listenplatz')

    direktkandidaten = list(
        map(
            lambda row: (
                uuid.uuid4(),
                partei_mapping[(row['Gruppenname'].upper(),)],
                row['kandId'],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                0
            ),
            direktkandidaten
        )
    )
    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                uuid.uuid4(),
                None,
                row['kandId'],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                0
            ),
            direktkandidaten_parteilos
        )
    )
    load_into_db(cursor, direktkandidaten + direktkandidaten_parteilos, 'Direktkandidatur')


if __name__ == '__main__':
    load_gemeinden(None)
