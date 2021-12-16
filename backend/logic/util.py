import csv
import itertools
import logging
import math
import time

import psycopg
import requests
import simplejson as json

logger = logging.getLogger('DB')


def reset_aggregates(cursor: psycopg.cursor, wahl: str, wknr: str):
    # recalculate aggregate
    exec_script(cursor,
                f"""
                UPDATE direktkandidatur
                        SET anzahlstimmen =
                                (SELECT COUNT(*)
                                FROM erststimme e
                                WHERE e.kandidatur = direktid)    
                        WHERE wahlkreis = (
                            SELECT wk.wkid
                            FROM wahlkreis wk
                            WHERE wk.nummer = {wknr}
                            AND wk.wahl = {wahl}
                        )
                """
                , 'ResetAggregates.sql')


def exec_script(cursor: psycopg.cursor, script: str, script_name: str) -> None:
    #### Timed Execution
    start_time = time.perf_counter()
    cursor.execute(script)
    truncated_script = script.replace('\n', ' ')[0:50]
    logger.info(
        f'Executed script {truncated_script + "....." if script_name is None else script_name} in ' +
        f'{(time.perf_counter() - start_time) * 1000 : .2f}ms')
    ####


def exec_script_from_file(cursor: psycopg.cursor, path: str) -> None:
    with open(path) as script:
        exec_script(cursor, script.read(), path)


def get_column_names(cursor: psycopg.cursor, table: str) -> list[str]:
    cursor.execute('SELECT * FROM %s' % table)
    col_names = [desc[0] for desc in cursor.description]
    return col_names


def load_into_db(cursor: psycopg.cursor, records: list, table: str) -> None:
    col_names = get_column_names(cursor, table)
    record_len = len(records[0])
    # Cut columns if necessary
    col_names = col_names[:record_len]
    with cursor.copy(f'COPY  {table}({",".join(col_names)}) FROM STDIN') as copy:
        #### Timed Execution
        start_time = time.perf_counter()
        for record in records:
            copy.write_row(record)
        logger.info(f'Copied {len(records)} rows into {table} in {(time.perf_counter() - start_time) * 1000 : .2f}ms')
        ####


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


def table_to_dict_list(cursor: psycopg.cursor, table: str, **kwargs) -> list[dict]:
    kwargs_str = " AND ".join([key + " = " + value for key, value in kwargs.items()])
    if len(kwargs) > 0:
        kwargs_str = "WHERE " + kwargs_str
    query = f"SELECT * FROM {table} {kwargs_str}"

    #### Timed Execution
    start_time = time.perf_counter()
    cursor.execute(query)
    fetching_time = time.perf_counter()
    res = cursor.fetchall()
    logger.info(
        f'Completed query {query[0:100]}..... in ' +
        f'(execution: {(fetching_time - start_time) * 1000 : .2f}ms, ' +
        f'fetching: {(time.perf_counter() - fetching_time) * 1000 : .2f}ms)')
    ####

    col_names = [desc.name for desc in cursor.description]
    arr = []
    for r in res:
        arr.append({col_names[i]: r[i] for i in range(0, len(col_names))})
    return arr


def key_dict(cursor: psycopg.cursor, table: str, keys: tuple[str], target: str) -> dict:
    keys = tuple(map(lambda key: key.lower(), keys))
    target = target.lower()
    return {tuple(row[key] for key in keys): row[target] for row in table_to_dict_list(cursor, table)}


def table_to_json(cursor: psycopg.cursor, table: str, **kwargs):
    return_single = kwargs.pop('single', False)
    table = table_to_dict_list(cursor, table, **kwargs)
    if return_single:
        return json.dumps(table[0])
    else:
        return json.dumps(table)


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


def valid_wahl(wahl: str):
    return models_nat(wahl) and int(wahl) in [19, 20]


def valid_wahlkreis(wknr: str):
    return models_nat(wknr) and 1 <= int(wknr) <= 299


if __name__ == '__main__':
    download_csv(
        'https://raw.githubusercontent.com/sumtxt/ags/master/data-raw'
        '/bundeslaender.csv'
    )
