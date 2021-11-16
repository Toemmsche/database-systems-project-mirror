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
            load_gemeinden(cursor)


if __name__ == '__main__':
    load_all()
