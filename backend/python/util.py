import csv
import itertools
import logging
import math
import time

import psycopg
import requests
import simplejson as json

logger = logging.getLogger('ETL')


def exec_script(cursor: psycopg.cursor, path: str) -> None:
    with open(path) as script:
        start_time = time.time()
        cursor.execute(script.read())
        logger.info(f'Executed script {path} in {time.time() - start_time}s')


def stimmen_generator(cursor: psycopg.cursor) -> None:
    with open('../sql/init/erststimmengenerator.sql') as stimmen_generator_script:
        start_time = time.time()
        cursor.execute(stimmen_generator_script.read())
        logger.info(f'Generated Erststimmen in {time.time() - start_time}s')

    with open('../sql/init/zweitstimmengenerator.sql') as stimmen_generator_script:
        start_time = time.time()
        cursor.execute(stimmen_generator_script.read())
        logger.info(f'Generated Zweitstimmen in {time.time() - start_time}s')


def get_column_names(cursor: psycopg.cursor, table: str) -> list[str]:
    cursor.execute('SELECT * FROM %s' % table)
    col_names = [desc[0] for desc in cursor.description]
    return col_names


def load_into_db(cursor: psycopg.cursor, records: list, table: str) -> None:
    '''
    Loads a list of records into a database table.
    '''
    col_names = get_column_names(cursor, table)
    record_len = len(records[0])
    # Cut columns if necessary
    col_names = col_names[:record_len]
    with cursor.copy(f'COPY  {table}({",".join(col_names)}) FROM STDIN') as copy:
        start_time = time.time()
        for record in records:
            copy.write_row(record)
        logger.info(f'Copied {len(records)} rows into {table} in {time.time() - start_time}s')


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
    return float(str.replace('.', '').replace(',', '.'))


def key_dict(cursor: psycopg.cursor, table: str, keys: tuple, target: str):
    res = cursor.execute('SELECT * FROM %s' % table).fetchall()
    col_names = [desc[0] for desc in cursor.description]
    keys = tuple(col_names.index(key.lower()) for key in keys)
    target = col_names.index(target.lower())
    d = {}
    for r in res:
        t = tuple(r[i] for i in keys)
        d.update({t: r[target]})
    return d


def query_result_to_json(cursor: psycopg.cursor, result: list):
    col_names = [desc[0] for desc in cursor.description]
    arr = []
    for r in result:
        arr.append({col_names[i]: r[i] for i in range(0, len(col_names))})
    return json.dumps(arr, use_decimal=True)


def single_result_to_json(cursor: psycopg.cursor, result: list):
    col_names = [desc[0] for desc in cursor.description]
    res = result[0]
    obj = {col_names[i]: res[i] for i in range(0, len(col_names))}
    return json.dumps(obj, use_decimal=True)


def table_to_json(cursor: psycopg.cursor, table: str):
    res = cursor.execute('SELECT * FROM %s' % table).fetchall()
    return query_result_to_json(cursor, res)


def make_unique(dicts: list[dict], key_values: tuple):
    unique_list = []
    key_set = set()
    for d in dicts:
        key = tuple(d[value] for value in key_values)
        if key not in key_set:
            unique_list.append(d)
            key_set.add(key)
    return unique_list


def notFalsy(s, d):
    if s:
        return s
    else:
        return d


def models_nat(num: str):
    try:
        x = int(num)
    except:
        return False
    return not math.isnan(x) and x >= 0


if __name__ == '__main__':
    download_csv(
        'https://raw.githubusercontent.com/sumtxt/ags/master/data-raw'
        '/bundeslaender.csv'
    )