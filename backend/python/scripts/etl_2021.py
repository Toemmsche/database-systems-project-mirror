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
            lambda row: (row['id'], row['label'], row['name_de'], 0, None),
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

    unique_landeslisten = dict()
    landeslisten = list()
    for kand in kandidaten_landesliste_1:
        key = (
            kand['Gebietsnummer'],
            kand['Gruppenname'],
            kand['GebietLandAbk']
        )
        if key not in unique_landeslisten:
            landeslisten.append(key)
            unique_landeslisten[key] = uuid.uuid4()

    for kand in kandidaten_landesliste_2:
        key = (
            kand['VerknGebietsnummer'],
            kand['VerknGruppenname'],
            kand['VerknGebietLandAbk']
        )
        if key not in unique_landeslisten:
            landeslisten.append(key)
            unique_landeslisten[key] = uuid.uuid4()

    parteireihenfolge = download_csv(parteireihenfolge_2021, delimiter=';')[4:]
    parteireihenfolge = {partei['Gruppenname_kurz'].upper(): partei for partei in parteireihenfolge}

    landeslisten = list(
        map(
            lambda liste: (
                unique_landeslisten[liste],
                partei_mapping[(liste[1].upper(),)],
                20,
                liste[0],
                parteireihenfolge[liste[1].upper()][liste[2]]
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
                unique_landeslisten[(row['Gebietsnummer'], row['Gruppenname'], row['GebietLandAbk'])]
            ),
            kandidaten_landesliste_1
        )
    )
    kandidaten_landesliste_2 = list(
        map(
            lambda row: (
                row['VerknListenplatz'],
                row['kandId'],
                unique_landeslisten[(row['VerknGebietsnummer'], row['VerknGruppenname'], row['VerknGebietLandAbk'])]
            ),
            kandidaten_landesliste_2
        )
    )
    load_into_db(cursor, kandidaten_landesliste_1 + kandidaten_landesliste_2, 'Listenplatz')


def load_direktkandidaten_2021(cursor: psycopg.cursor) -> None:
    records = local_csv(kandidaten_2021, delimiter=';')
    ergebnisse = download_csv(ergebnisse_2021, delimiter=';', skip=9)

    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    partei_mapping = {(x[0].upper(),): partei_mapping[x] for x in partei_mapping}
    wahlkreis_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl',), 'wkId')
    kandidaten_mapping = key_dict(cursor, 'kandidat', ('vorname', 'nachname', 'geburtsjahr'), 'kandId')

    ergebnisse = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and row['Gruppenart'] == 'Partei' and row['Stimme'] == '1' and
                        row['Anzahl'] != '',
            ergebnisse
        )
    )
    ergebnisse_dict = {
        (ergebnis['Gruppenname'], int(ergebnis['Gebietsnummer'])): int(ergebnis['Anzahl']) for ergebnis in ergebnisse
    }

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

    direktkandidaten = list(
        map(
            lambda row: (
                uuid.uuid4(),
                partei_mapping[(row['Gruppenname'].upper(),)],
                kandidaten_mapping[(row['Vornamen'], row['Nachname'], int(row['Geburtsjahr']),)],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                ergebnisse_dict[(row['Gruppenname'], int(row['Gebietsnummer']))]
            ),
            direktkandidaten
        )
    )
    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                uuid.uuid4(),
                None,
                kandidaten_mapping[(row['Vornamen'], row['Nachname'], int(row['Geburtsjahr']),)],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                0
            ),
            direktkandidaten_parteilos
        )
    )
    load_into_db(cursor, direktkandidaten + direktkandidaten_parteilos, 'Direktkandidatur')


def load_zweitstimmen_2021(cursor: psycopg.cursor) -> None:
    records = download_csv(ergebnisse_2021, delimiter=';', skip=9)

    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    partei_mapping = {(x[0].upper(),): partei_mapping[x] for x in partei_mapping}
    wahlkreis_mapping = key_dict(cursor, 'wahlkreis', ('nummer', 'wahl',), 'wkId')
    landesliste_mapping = key_dict(cursor, 'landesliste', ('partei', 'wahl', 'land',), 'listenId')

    zweitstimmenergebnisse = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and row['Gruppenart'] == 'Partei' and row['Stimme'] == '2' and row['Anzahl'] != '',
            records
        )
    )
    zweitstimmenergebnisse = list(
        map(
            lambda row: (
                landesliste_mapping[(partei_mapping[(row['Gruppenname'].upper(),)], 20, int(row['UegGebietsnummer']))],
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                row['Anzahl']
            ),
            zweitstimmenergebnisse
        )
    )
    load_into_db(cursor, zweitstimmenergebnisse, 'Zweitstimmenergebnis')


if __name__ == '__main__':
    load_gemeinden(None)
