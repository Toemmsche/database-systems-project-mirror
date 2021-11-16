import csv
import logging
import requests

import psycopg

logger = logging.getLogger('ETL')


def init_db(cursor: psycopg.cursor) -> None:
    '''
    Resets the state of the election database using the init.sql script.
    '''
    with open('../../sql/init.sql') as init_script:
        cursor.execute(init_script.read())
        logger.info('Reset database')


def load_into_db(cursor: psycopg.cursor, records: list, table: str) -> None:
    '''
    Loads a list of records into a database table.
    '''
    with cursor.copy('COPY {} FROM STDIN'.format(table)) as copy:
        for record in records:
            copy.write_row(record)
        logger.info('Wrote {} rows into {}'.format(str(len(records)), table))


def download_csv(url: str) -> csv:
    response = requests.get(url, stream=True)
    response.raw.decode_content = True
    lines = response.content.decode().split('\n')
    file = csv.reader(lines)
    return file


if __name__ == '__main__':
    download_csv(
        'https://raw.githubusercontent.com/sumtxt/ags/master/data-raw/bundeslaender.csv'
        )
