import os
from logic.ExtractTransformLoad import *
from logic.config import db_config


def init_all() -> None:
    # open database connection
    with psycopg.connect(**db_config) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # reset first
            exec_script_from_file(cursor, 'sql/init/init.sql')

            # load data for 2021
            load_bundestagswahl_2021(cursor)
            load_bundeslaender(cursor)

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
            load_gemeinden(gemeinden_2021, 20, cursor)
            load_parteien(cursor)
            load_landeslisten_2021(cursor)
            load_kandidaten_2021(cursor)
            load_listenplaetze_2021(cursor)
            load_direktkandidaten_2021(cursor)
            load_zweitstimmen_2021(cursor)

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
            load_gemeinden(gemeinden_2017, 19, cursor, 'cp1252')
            load_landeslisten_2017(cursor)
            load_zweitstimmen_2017(cursor)
            load_direktkandidaten_2017(cursor)

            # exec_script_from_file(cursor, 'sql/init/StimmenGenerator.sql')


def exec_util_queries():
    # open database connection
    with psycopg.connect(**db_config) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            exec_script_from_file(cursor, 'sql/core/Einzelstimmen222.sql')
            exec_script_from_file(cursor, 'sql/core/bundestag_with_2017.sql')


def exec_data_queries():
    # open database connection
    with psycopg.connect(**db_config) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # open scritp directory
            for root, dirs, files in os.walk('sql/queries'):  #
                for file in files:
                    fullpath = os.path.join(root, file)
                    exec_script_from_file(cursor, fullpath)

def exec_refresh_scripts():
    # open database connection
    with psycopg.connect(**db_config) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # open scritp directory
            for root, dirs, files in os.walk('sql/refresh'):  #
                for file in files:
                    fullpath = os.path.join(root, file)
                    exec_script_from_file(cursor, fullpath)


def init_backend():
    init_all()
    exec_util_queries()
    exec_data_queries()
    #exec_refresh_scripts()


if __name__ == '__main__':
    init_backend()
