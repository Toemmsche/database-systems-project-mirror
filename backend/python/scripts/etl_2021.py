import itertools
import uuid

import psycopg
from psycopg.types import datetime
from util import *
from links import *
from functional import seq


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


def load_wahlkreise(
        url: str, wahl: int, deutsche_key: str, cursor: psycopg.cursor,
        encoding: str = 'utf-8-sig'
) -> None:
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


def load_landeslisten_2021(cursor: psycopg.cursor) -> None:
    parteireihenfolge = download_csv(parteireihenfolge_2021, delimiter=';')[4:]

    parteien_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    parteien_mapping = {(kuerzel[0].upper(),): parteiId for
                        kuerzel, parteiId in parteien_mapping.items()}
    bundesland_mapping = key_dict(cursor, 'Bundesland', ('kuerzel',), 'landId')

    landeslisten = []
    for partei in parteireihenfolge:
        if partei['Gruppenname_kurz'] != 'Übrige':
            for bl, pos in partei.items():
                if bl != 'Gruppenname_kurz' and bl != 'BUND' and pos != '':
                    landeslisten.append(
                        (
                            uuid.uuid4(),
                            parteien_mapping[(
                                partei['Gruppenname_kurz'].upper(),
                            )],
                            20,
                            bundesland_mapping[(bl,)],
                            pos,
                        )
                    )
    load_into_db(cursor, landeslisten, 'Landesliste')


def load_kandidaten_2021(cursor: psycopg.cursor) -> None:
    kandidaten = local_csv(kandidaten_2021, delimiter=';')

    # make candidates unique
    kandidaten = make_unique(
        kandidaten,
        ('Vornamen', 'Nachname', 'Geburtsjahr')
    )

    records = list(
        map(
            lambda row: (
                row['uuid'],
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
            kandidaten,
        )
    )
    load_into_db(cursor, records, 'Kandidat')


def get_listenplaetze_2021_prefix(cursor: psycopg.cursor, prefix: str) -> \
        list[tuple]:
    kandidaten = local_csv(kandidaten_2021, delimiter=';')
    kandidaten = make_unique(
        kandidaten,
        ('Vornamen', 'Nachname', 'Geburtsjahr'),
    )
    parteien_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    landeslisten_mapping = key_dict(
        cursor,
        'Landesliste',
        ('partei', 'land'),
        'listenId',
    )
    kandidaten_mapping = key_dict(
        cursor,
        'kandidat',
        ('Vorname', 'Nachname', 'Geburtsjahr'),
        'kandId',
    )

    kandidaten = filter(
        lambda row: row[prefix + 'Gebietsnummer'] != '' and
                    row[prefix + 'Gebietsart'] == 'Land',
        kandidaten,
    )

    listenplaetze = list(
        map(
            lambda row: (
                row[prefix + 'Listenplatz'],
                kandidaten_mapping[(
                    row['Vornamen'],
                    row['Nachname'],
                    int(row['Geburtsjahr']),
                )],
                landeslisten_mapping[(
                    parteien_mapping[(row[prefix + 'Gruppenname'],)],
                    int(row[prefix + 'Gebietsnummer']),
                )]
            ),
            kandidaten
        )
    )
    return listenplaetze


def load_listenplaetze_2021(cursor: psycopg.cursor) -> None:
    listenplaetze_1 = get_listenplaetze_2021_prefix(cursor, '')
    listenplaetze_2 = get_listenplaetze_2021_prefix(cursor, 'Verkn')
    load_into_db(
        cursor,
        listenplaetze_1 + listenplaetze_2,
        'Listenplatz'
    )


def load_direktkandidaten_2021(cursor: psycopg.cursor) -> None:
    records = local_csv(kandidaten_2021, delimiter=';')
    ergebnisse = download_csv(ergebnisse_2021, delimiter=';', skip=9)

    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    partei_mapping = {(x[0].upper(),): partei_mapping[x] for x in
                      partei_mapping}
    wahlkreis_mapping = key_dict(
        cursor,
        'wahlkreis',
        ('nummer', 'wahl',),
        'wkId'
    )
    kandidaten_mapping = key_dict(
        cursor,
        'kandidat',
        ('vorname', 'nachname', 'geburtsjahr'),
        'kandId'
    )

    ergebnisse_partei = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'Partei' and
                        row['Stimme'] == '1' and
                        row['Anzahl'] != '',
            ergebnisse
        )
    )
    ergebnisse_partei_dict = {
        (ergebnis['Gruppenname'], int(ergebnis['Gebietsnummer'])): int(
            ergebnis['Anzahl']
        ) for ergebnis in ergebnisse_partei
    }

    ergebnisse_parteilos = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and row[
                'Gruppenart'] == 'Einzelbewerber/Wählergruppe' and row[
                            'Stimme'] == '1',
            ergebnisse
        )
    )
    ergebnisse_parteilos_dict = {
        ergebnis['Gruppenname']: int(ergebnis['Anzahl']) for ergebnis in
        ergebnisse_parteilos
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
                None,
                kandidaten_mapping[(
                    row['Vornamen'], row['Nachname'],
                    int(row['Geburtsjahr']),)],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                ergebnisse_partei_dict[
                    (row['Gruppenname'], int(row['Gebietsnummer']))]
            ),
            direktkandidaten
        )
    )
    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                uuid.uuid4(),
                None,
                row['Gruppenname'],
                kandidaten_mapping[(
                    row['Vornamen'], row['Nachname'],
                    int(row['Geburtsjahr']),)],
                20,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                ergebnisse_parteilos_dict[row['Gruppenname']] if row[
                                                                     'Gruppenname'] in ergebnisse_parteilos_dict else
                ergebnisse_parteilos_dict[row['GruppennameLang']]
            ),
            direktkandidaten_parteilos
        )
    )
    load_into_db(
        cursor,
        direktkandidaten + direktkandidaten_parteilos,
        'Direktkandidatur'
    )


def load_zweitstimmen_2021(cursor: psycopg.cursor) -> None:
    records = download_csv(ergebnisse_2021, delimiter=';', skip=9)

    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    partei_mapping = {(x[0].upper(),): partei_mapping[x] for x in
                      partei_mapping}
    wahlkreis_mapping = key_dict(
        cursor,
        'wahlkreis',
        ('nummer', 'wahl',),
        'wkId'
    )
    landesliste_mapping = key_dict(
        cursor,
        'landesliste',
        ('partei', 'wahl', 'land',),
        'listenId'
    )

    zweitstimmenergebnisse = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'Partei' and
                        row['Stimme'] == '2' and
                        row['Anzahl'] != '',
            records
        )
    )
    zweitstimmenergebnisse = list(
        map(
            lambda row: (
                landesliste_mapping[(
                    partei_mapping[(row['Gruppenname'].upper(),)],
                    20,
                    int(row['UegGebietsnummer']),
                )],
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                row['Anzahl']
            ),
            zweitstimmenergebnisse
        )
    )
    load_into_db(cursor, zweitstimmenergebnisse, 'Zweitstimmenergebnis')


def load_landeslisten_2017(cursor: psycopg.cursor) -> None:
    ergebnisse = download_csv(ergebnisse_2021, delimiter=';', skip=9)
    print(ergebnisse[1:2])
    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')
    landeslisten = (seq(ergebnisse)
        .filter(
        lambda row: row['UegGebietsart'] == 'BUND' and
                    row['Gruppenart'] == 'Partei' and
                    row['Stimme'] == '2' and
                    row['VorpAnzahl'] != ''
    )
        .map(
        lambda row: (
            row['Gebietsnummer'],
            row['Gruppenname'],
        )
    ))

    # eliminate duplicates
    landeslisten = list(set(landeslisten))

    landeslisten = list(
        map(
            lambda row: (
                uuid.uuid4(),
                partei_mapping[(row[1],)],
                19,
                row[0],
                -1,
            ),
            landeslisten
        )
    )
    load_into_db(cursor, landeslisten, 'Landesliste')


if __name__ == '__main__':
    load_landeslisten_2021(None)
