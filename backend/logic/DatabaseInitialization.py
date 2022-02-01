import os

from logic.ETL_2017 import *
from logic.ETL_2021 import *
from logic.ETL_general import *
from logic.config import conn_string, heroku


def init_tables(cursor: psycopg.Cursor) -> None:
    # reset first
    exec_sql_statement_from_file(cursor, 'sql/init/init.sql')
    # indices
    exec_sql_statement_from_file(cursor, 'sql/init/Indices.sql')

    logger.info("Initialized tables and indices")


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
        wahlkreise_2021,
        20,
        'Bevölkerung am 31.12.2019 - Deutsche (in 1000)',
        begrenzungen_2021,
        begrenzungen_dict,
        cursor
    )
    # There are over 10k communities in Germany
    if not heroku:
        load_gemeinden(gemeinden_2021, 20, cursor)
    load_parteien(cursor)
    load_landeslisten_2021(cursor)
    load_kandidaten_2021(cursor)
    load_listenplaetze_2021(cursor)
    load_direktkandidaten_2021(cursor)
    load_zweitstimmen_2021(cursor)

    logger.info("Loaded data for 2021")

    # 2017
    load_wahlkreise(
        wahlkreise_2017,
        19,
        'Bevölkerung am 31.12.2015 - Deutsche (in 1000)',
        begrenzungen_2021,
        begrenzungen_dict,
        cursor,
        'cp1252'
    )
    # There are over 10k communities in Germany
    if not heroku:
        load_gemeinden(gemeinden_2017, 19, cursor, 'cp1252')
    load_landeslisten_2017(cursor)
    load_zweitstimmen_2017(cursor)
    load_direktkandidaten_2017(cursor)

    logger.info("Loaded data for 2017")

    # Cannot afford to store that many individual votes on a free plan
    if not heroku:
        exec_sql_statement_from_file(cursor, 'sql/init/Einzelstimmen.sql')
    exec_sql_statement_from_file(cursor, 'sql/init/Token.sql')

    logger.info("Generated Einzelstimmen and (admin) tokens")


def exec_util_queries(cursor: psycopg.Cursor):
    exec_sql_statement_from_file(cursor, 'sql/core/bundestag_with_2017.sql')
    exec_sql_statement_from_file(cursor, 'sql/core/Triggers.sql')
    exec_sql_statement_from_file(cursor, 'sql/core/bundestag_triggers.sql')
    logger.info("Loaded utility views and triggers")


def exec_data_queries(cursor: psycopg.Cursor):
    # open script directory
    for root, dirs, files in os.walk('sql/queries'):
        for file in files:
            full_path = os.path.join(root, file)
            exec_sql_statement_from_file(cursor, full_path)
    logger.info("Loaded data views")


def init_backend():
    with psycopg.connect(conn_string).cursor() as cursor:
        init_tables(cursor)
        init_data(cursor)
        exec_util_queries(cursor)
        exec_data_queries(cursor)


if __name__ == '__main__':
    init_backend()
