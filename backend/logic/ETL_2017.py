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
                wahlkreis_mapping[(int(row['Gebietsnummer']), 19,)],
                int(row['Anzahl'])
            ),
            ergebnisse_partei
        )
    )

    # ========================================================================
    # Parteilose Direktkandidaten
    # ========================================================================

    ergebnisse_parteilos = list(
        filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'Einzelbewerber/Wählergruppe' and
                        row['Stimme'] == '1' and
                        row['Anzahl'] != '',
            ergebnisse
        )
    )

    # insert party for each parteiloser direktkandidat
    einzelbewerber_parteien = seq(ergebnisse_parteilos).map(
        lambda row: (
            True,  # is Einzelbewerber
            f"WK-{int(row['Gebietsnummer'])}-{row['Gruppenname']}",
            row['Gruppenname'],
            False,
            None,
            'B07802',  # random color
        )
    ).to_set()

    load_into_db(cursor, list(einzelbewerber_parteien), "partei")

    # Reload partei mapping with 'name' and 'kuerzel'
    partei_mapping = key_dict(cursor, 'partei', ('name', 'kuerzel'), 'parteiId')

    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                partei_mapping[(f"WK-{int(row['Gebietsnummer'])}-{row['Gruppenname']}", row['Gruppenname'])],
                None,
                wahlkreis_mapping[(int(row['Gebietsnummer']), 19,)],
                int(row['Anzahl'])
            ),
            ergebnisse_parteilos
        )
    )

    # Reload partei mapping with 'name' and 'kuerzel'
    partei_mapping = key_dict(cursor, 'partei', ('name', 'kuerzel'), 'parteiId')
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


def load_ungueltige_stimmen_2017(cursor: psycopg.Cursor):
    records = download_csv(ergebnisse_2017, delimiter=';', skip=9)

    wahlkreis_mapping = key_dict(
        cursor,
        'wahlkreis',
        ('nummer', 'wahl',),
        'wkId'
    )
    ungueltige_stimmen_ergebnisse = list(
        seq(records)
            .filter(
            lambda row: row['Gebietsart'] == 'Wahlkreis' and
                        row['Gruppenart'] == 'System-Gruppe' and
                        row['Gruppenname'] == 'Ungültige'
        ).map(
            lambda row: (
                (
                    int(row['Stimme']),
                    wahlkreis_mapping[(int(row['Gebietsnummer']), 19)],
                    int(row['Anzahl'])
                )
            )
        )
    )
    load_into_db(cursor, ungueltige_stimmen_ergebnisse, 'ungueltige_stimmen_ergebnis')
