from functional import seq

from logic.links import *
from logic.util import *


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
                row['Vornamen'],
                row['Nachname'],
                row['Titel'],
                row['Namenszusatz'],
                row['Geburtsjahr'],
                row['Geburtsort'],
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
        ('partei', 'land', 'wahl'),
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
                    20
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


def load_direktkandidaten_2021(cursor: psycopg.cursor, generate_stimmen: bool = False) -> None:
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
    direktkandidaten = list(
        filter(
            lambda row: row['Kennzeichen'] == 'Kreiswahlvorschlag',
            records
        )
    )
    direktkandidaten = list(
        map(
            lambda row: (
                partei_mapping[(row['Gruppenname'].upper(),)],
                kandidaten_mapping[(
                    row['Vornamen'], row['Nachname'],
                    int(row['Geburtsjahr']),)],
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                ergebnisse_partei_dict[
                    (row['Gruppenname'], int(row['Gebietsnummer']))]
            ),
            direktkandidaten
        )
    )

    # ========================================================================
    # Parteilose Direktkandidaten
    # ========================================================================

    ergebnisse_parteilos = seq(ergebnisse).filter(
        lambda row: row['Gebietsart'] == 'Wahlkreis' and row[
            'Gruppenart'] == 'Einzelbewerber/Wählergruppe' and row[
                        'Stimme'] == '1'
    )
    ergebnisse_parteilos_dict = {
        (int(ergebnis['Gebietsnummer']), ergebnis['Gruppenname']): ergebnis['Anzahl'] for ergebnis in
        ergebnisse_parteilos
    }

    direktkandidaten_parteilos = list(
        filter(
            lambda row: row['Kennzeichen'] == 'anderer Kreiswahlvorschlag',
            records
        )
    )

    # insert party for each parteiloser direktkandidat
    einzelbewerber_parteien = seq(direktkandidaten_parteilos).map(
        lambda row: (
            True,  # is Einzelbewerber
            row['GruppennameLang'],
            row['Gruppenname'],
            False,
            None,
            'B07802',  # random color
        )
    ).to_set()

    load_into_db(cursor, list(einzelbewerber_parteien), "partei")

    # maps (wahlkreis, gruppenname) to (vorname, nachname, geburtsjahr)
    einzelbewerber_wahlkreis_dict = {
        (einzelbewerber['Vornamen'], einzelbewerber['Nachname'], einzelbewerber['Geburtsjahr'])
        : int(einzelbewerber['Gebietsnummer'])
        for einzelbewerber in direktkandidaten_parteilos
    }

    # Reload partei mapping with 'name' and 'kuerzel'
    partei_mapping = key_dict(cursor, 'partei', ('name', 'kuerzel'), 'parteiId')

    direktkandidaten_parteilos = list(
        map(
            lambda row: (
                partei_mapping[(row['GruppennameLang'], row['Gruppenname'])],
                kandidaten_mapping[(
                    row['Vornamen'], row['Nachname'],
                    int(row['Geburtsjahr']))],
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20,)],
                int(
                    ergebnisse_parteilos_dict[
                        (
                            einzelbewerber_wahlkreis_dict[(row['Vornamen'], row['Nachname'], row['Geburtsjahr'])],
                            row['GruppennameLang'] if (einzelbewerber_wahlkreis_dict[
                                                           (row['Vornamen'], row['Nachname'], row['Geburtsjahr'])],
                                                       row['GruppennameLang']) in ergebnisse_parteilos_dict
                            else row['Gruppenname']  # they just cant decide which one to use
                        )
                    ]
                )
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
                int(row['Anzahl'])
            ),
            zweitstimmenergebnisse
        )
    )
    load_into_db(cursor, zweitstimmenergebnisse, 'Zweitstimmenergebnis')


def load_ungueltige_stimmen_2021(cursor: psycopg.Cursor):
    records = download_csv(ergebnisse_2021, delimiter=';', skip=9)

    wahlkreis_mapping = key_dict(
        cursor,
        'wahlkreis',
        ('nummer', 'wahl',),
        'wkId'
    )
    ungueltige_stimmen_ergebnisse = seq(records).filter(
        lambda row: row['Gebietsart'] == 'Wahlkreis' and
                    row['Gruppenart'] == 'System-Gruppe' and
                    row['Gruppenname'] == 'Ungültige'
    ).map(
        lambda row: (
            (
                int(row['Stimme']),
                wahlkreis_mapping[(int(row['Gebietsnummer']), 20)],
                int(row['Anzahl'])
            )
        )
    ).to_list()

    load_into_db(cursor, ungueltige_stimmen_ergebnisse, 'ungueltige_stimmen_ergebnis')


if __name__ == '__main__':
    load_landeslisten_2021(None)
