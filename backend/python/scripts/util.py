import csv
import itertools
import logging
import requests

import psycopg
from psycopg2 import sql

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
        logger.info('Copied {} rows into {}'.format(str(len(records)), table))


def parse_csv(string: str, delimiter, skip) -> list[dict]:
    lines = string.split('\n')
    file = [{k: v for k, v in row.items()}
            for row in csv.DictReader(
            itertools.islice(
                filter(lambda row: row != "" and row[0] != '#', lines),
                skip,
                None
                ),
            delimiter=delimiter,
            skipinitialspace=True
        )]
    return file


def local_csv(path: str, delimiter=',', encoding='utf-8-sig', skip=0) -> list[
    dict]:
    with open(path, 'r', encoding=encoding) as f:
        return parse_csv(f.read(), delimiter, skip)


def download_csv(url: str, delimiter=',', encoding='utf-8-sig', skip=0) -> list[
    dict]:
    response = requests.get(url, stream=True)
    content = response.content.decode(encoding)
    return parse_csv(content, delimiter, skip)

def parse_float_de(str: str) -> float:
    return float(str.replace('.', '').replace(',','.'))


def key_dict(cursor, table: str, keys: tuple, target: str):
    res = cursor.execute('SELECT * FROM %s' % table)
    col_names = [desc[0] for desc in cursor.description]
    keys = tuple(col_names.index(key.lower()) for key in keys)
    target = col_names.index(target.lower())
    d = {}
    for r in res:
        t = tuple(r[i] for i in keys)
        d.update({t: r[target]})
    return d


def notFalsy(s, d):
    if s:
        return s
    else:
        return d


if __name__ == '__main__':
    download_csv(
        'https://raw.githubusercontent.com/sumtxt/ags/master/data-raw'
        '/bundeslaender.csv'
    )
