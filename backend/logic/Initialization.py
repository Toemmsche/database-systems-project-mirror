import os
from timeit import default_timer as timer

from logic.ETL_2017 import *
from logic.ETL_2021 import *
from logic.ETL_general import *
from logic.config import conn_string, heroku

from logic.config import load_all_einzelstimmen


def init_tables(cursor: psycopg.Cursor) -> None:
    # reset first
    exec_sql_statement_from_file(cursor, 'sql/init/init.sql')

    logger.info("Initialized tables")


def init_data(cursor: psycopg.Cursor) -> None:
    # load data for 2021
    load_bundestagswahl(cursor)
    load_bundeslaender(cursor)

    logger.info("Loaded general data")

    # Make sure that Wahlkreise and SVG paths are matched correctly
    begrenzungen_dict = {
        10: 299
    }
    for i in range(1, 10):
        begrenzungen_dict[i] = i
    for i in range(11, 300):
        begrenzungen_dict[i] = i - 1

    load_wahlkreise(
        strukturdaten_2021_local,
        20,
        'Bevölkerung am 31.12.2019 - Deutsche (in 1000)',
        begrenzungen_2021,
        begrenzungen_dict,
        cursor
    )
    load_parteien(cursor)
    load_landeslisten_2021(cursor)
    load_parteihenreinfolge_2021(cursor)
    load_kandidaten_2021(cursor)
    load_listenplaetze_2021(cursor)
    load_direktkandidaten_2021(cursor)
    load_zweitstimmen_2021(cursor)
    load_ungueltige_stimmen_2021(cursor)
    logger.info("Loaded data for 2021")

    # 2017
    load_wahlkreise(
        strukturdaten_2017_local,
        19,
        'Bevölkerung am 31.12.2015 - Deutsche (in 1000)',
        begrenzungen_2021,
        begrenzungen_dict,
        cursor,
        'cp1252'
    )
    load_landeslisten_2017(cursor)
    load_zweitstimmen_2017(cursor)
    load_ungueltige_stimmen_2017(cursor)
    load_direktkandidaten_2017(cursor)

    logger.info("Loaded data for 2017")

    if load_all_einzelstimmen:
        load_einzelstimmen(cursor)
    else:
        load_einzelstimmen(cursor, wahlkreise=[217, 218, 219, 220, 221])

    logger.info("Generated Einzelstimmen ")

    exec_sql_statement_from_file(cursor, 'sql/init/Token.sql')

    logger.info("Generated (admin) tokens")

    exec_sql_statement_from_file(cursor, 'sql/init/Indizes.sql')

    logger.info("Created indices")


def load_einzelstimmen(cursor: psycopg.cursor, **kwargs):
    dk_query = f"""
        SELECT wk.wkid AS wahlkreis, dk.direktid, dk.anzahlstimmen
        FROM direktkandidatur dk, wahlkreis wk
        WHERE wk.wkid = dk.wahlkreis
    """

    direktkandidaturen = query_to_dict_list(cursor, dk_query)
    zweitstimmenergebnisse = table_to_dict_list(cursor, 'zweitstimmenergebnis')
    ungueltige_stimmen_ergebnisse = table_to_dict_list(cursor, 'ungueltige_stimmen_ergebnis')

    if not heroku:
        cursor.execute("SET session_replication_role = 'replica';")

    limit_wahlkreise = False
    if 'wahlkreise' in kwargs:
        limit_wahlkreise = True
        wahlkreise = set(kwargs['wahlkreise'])
        logger.info(f"Limiting generation of Einzelstimmen to {wahlkreise}")

    erststimmen = []
    for dk in direktkandidaturen:
        direktid = dk['direktid']
        wahlkreis = dk['wahlkreis']
        if not limit_wahlkreise or wahlkreis in wahlkreise:
            for i in range(0, dk['anzahlstimmen']):
                erststimmen.append((direktid,))

    load_into_db(cursor, erststimmen, 'erststimme')
    del erststimmen
    logger.info("Loaded einzelne Erststimmen")

    zweitstimmen = []
    for ze in zweitstimmenergebnisse:
        liste = ze['liste']
        wahlkreis = ze['wahlkreis']
        if not limit_wahlkreise or wahlkreis in wahlkreise:
            for i in range(0, ze['anzahlstimmen']):
                zweitstimmen.append((liste, wahlkreis))

    load_into_db(cursor, zweitstimmen, 'zweitstimme')
    del zweitstimmen
    logger.info("Loaded einzelne Zweitstimmen")

    ungueltige_stimmen = []
    for use in ungueltige_stimmen_ergebnisse:
        stimmentyp = use['stimmentyp']
        wahlkreis = use['wahlkreis']
        if not limit_wahlkreise or wahlkreis in wahlkreise:
            for i in range(0, use['anzahlstimmen']):
                ungueltige_stimmen.append((stimmentyp, wahlkreis))

    load_into_db(cursor, ungueltige_stimmen, 'ungueltige_stimme')
    del ungueltige_stimmen
    logger.info("Loaded einzelne ungueltige Stimmen")

    if not heroku:
        cursor.execute("SET session_replication_role = 'origin';")


def exec_util_queries(cursor: psycopg.Cursor):
    exec_sql_statement_from_file(cursor, 'sql/bundestag/DivisorVerfahren.sql')
    exec_sql_statement_from_file(cursor, 'sql/bundestag/Bundestag.sql')
    exec_sql_statement_from_file(cursor, 'sql/init/Triggers.sql')
    exec_sql_statement_from_file(cursor, 'sql/bundestag/BundestagTriggers.sql')
    logger.info("Loaded utility views and triggers")


def exec_data_queries(cursor: psycopg.Cursor):
    # open script directory
    for root, dirs, files in os.walk('sql/queries'):
        for file in files:
            full_path = os.path.join(root, file)
            exec_sql_statement_from_file(cursor, full_path)
    logger.info("Loaded data views")


def init_backend():
    start_time = timer()
    with psycopg.connect(conn_string) as conn:
        with conn.cursor() as cursor:
            init_tables(cursor)
            init_data(cursor)
            exec_util_queries(cursor)
            exec_data_queries(cursor)
    logger.info(f"Initialization took {timer() - start_time}s")


if __name__ == '__main__':
    init_backend()
