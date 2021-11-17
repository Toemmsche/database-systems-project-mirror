import os

from etl_2021 import *

import logging

# adjust logger config
logging.basicConfig()
logging.root.setLevel(logging.NOTSET)


def load_all() -> None:
    # open database connection
    with psycopg.connect(
            dbname='wahl',
            user='postgres',
            password=os.environ.get('POSTGRES_PWD')
    ) as conn:
        # create cursor to perform database operations
        with conn.cursor() as cursor:
            # reset first
            init_db(cursor)

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


if __name__ == '__main__':
    load_all()
