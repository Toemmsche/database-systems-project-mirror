from functional import seq

from logic.links import *
from logic.util import *


def load_direktkandidaten_2017(cursor: psycopg.cursor) -> None:
    ergebnisse = download_csv(ergebnisse_2017, delimiter=';', skip=9)
    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')

    # TODO
    partei_mapping.update({('Neue Liberale',): partei_mapping[('SL',)]})
    partei_mapping.update({('MG',): partei_mapping[('Gartenpartei',)]})

    wahlkreis_mapping = key_dict(
        cursor,
        'wahlkreis',
        ('nummer', 'wahl',),
        'wkId'
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
    direktkandidaten_partei = list(
        map(
            lambda row: (
                partei_mapping[(row['Gruppenname'],)],
                None,
                None,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 19,)],
                int(row['Anzahl'])
            ),
            ergebnisse_partei
        )
    )

    ergebnisse_parteilos = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'Einzelbewerber/Wählergruppe' and
                        row['Stimme'] == '1' and
                        row['Anzahl'] != '',
            ergebnisse
        )
    )
    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                None,
                row['Gruppenname'],
                None,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 19,)],
                int(row['Anzahl'])
            ),
            ergebnisse_parteilos
        )
    )

    load_into_db(
        cursor,
        direktkandidaten_partei + direktkandidaten_parteilos,
        'Direktkandidatur'
    )


def load_landeslisten_2017(cursor: psycopg.cursor) -> None:
    ergebnisse = download_csv(ergebnisse_2017, delimiter=';', skip=9)
    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')

    # TODO
    partei_mapping.update({('MG',): partei_mapping[('Gartenpartei',)]})

    landeslisten = list(
        seq(ergebnisse)
            .filter(
            lambda row: row['Gebietsart'] == 'Land' and
                        row['Gruppenart'] == 'Partei' and
                        row['Stimme'] == '2' and
                        row['Anzahl'] != ''
        )
            .map(
            lambda row: (
                partei_mapping[(row['Gruppenname'],)],
                19,
                row['Gebietsnummer'],
                -1
            )
        )
    )
    load_into_db(cursor, landeslisten, 'Landesliste')


def load_zweitstimmen_2017(cursor: psycopg.cursor) -> None:
    ergebnisse = download_csv(ergebnisse_2017, delimiter=';', skip=9)
    partei_mapping = key_dict(cursor, 'partei', ('kuerzel',), 'parteiId')

    # TODO
    partei_mapping.update({('MG',): partei_mapping[('Gartenpartei',)]})

    listen_mapping = key_dict(
        cursor,
        'landesliste',
        ('partei', 'land', 'wahl'),
        'listenId',
    )
    wahlkreis_mapping = key_dict(
        cursor,
        'Wahlkreis',
        ('nummer', 'wahl'),
        'wkId'
    )
    zweitstimmenergebnisse = list(
        seq(ergebnisse)
            .filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'Partei' and
                        row['Stimme'] == '2' and
                        row['Anzahl'] != ''
        )
            .map(
            lambda row: (
                listen_mapping[(
                    partei_mapping[(row['Gruppenname']),],
                    int(row['UegGebietsnummer']),
                    19,
                )],
                wahlkreis_mapping[(
                    int(row['Gebietsnummer']),
                    19
                )],
                row['Anzahl'],
            )
        )
    )
    load_into_db(cursor, zweitstimmenergebnisse, 'Zweitstimmenergebnis')
