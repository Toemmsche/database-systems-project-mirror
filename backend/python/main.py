import logging
import os

from etl_2021 import *

# adjust logger config
logging.basicConfig()
logging.root.setLevel(logging.NOTSET)


def init_all() -> None:
    # open database connection
    with psycopg.connect(
            dbname='wahl',
            user='postgres',
            password=os.environ.get('POSTGRES_PWD')
    ) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # reset first
            exec_script(cursor, '../sql/init/init.sql')

            # load data for 2021
            load_bundestagswahl_2021(cursor)
            load_bundeslaender(cursor)
            load_wahlkreise(
                wahlkreise_2021,
                20,
                'Bevölkerung am 31.12.2019 - Deutsche (in 1000)',
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
                cursor,
                'cp1252'
            )
            load_gemeinden(gemeinden_2017, 19, cursor, 'cp1252')
            load_landeslisten_2017(cursor)
            load_zweitstimmen_2017(cursor)
            load_direktkandidaten_2017(cursor)

            # stimmen_generator(cursor)


def exec_util_queries():
    # open database connection
    with psycopg.connect(
            dbname='wahl',
            user='postgres',
            password=os.environ.get('POSTGRES_PWD')
    ) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            exec_script(cursor, '../sql/util/bundestag_merged.sql')
            exec_script(cursor, '../sql/util/util_views.sql')


def exec_data_queries():
    # open database connection
    with psycopg.connect(
            dbname='wahl',
            user='postgres',
            password=os.environ.get('POSTGRES_PWD')
    ) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # open scritp directory
            for root, dirs, files in os.walk('../sql/queries'):  #
                for file in files:
                    fullpath = os.path.join(root, file)
                    exec_script(cursor, fullpath)


def init_backend():
    init_all()
    exec_util_queries()
    exec_data_queries()


if __name__ == '__main__':
    init_backend()
