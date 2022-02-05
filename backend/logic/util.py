import csv
import itertools
import logging
import math
from uuid import *


import requests
from logic.SQL_util import *

# adjust logger config
logging.basicConfig()
logging.root.setLevel(logging.NOTSET)
logger = logging.getLogger('DB')


def reset_aggregates(cursor: psycopg.cursor, wahl: int, wknr: int) -> bool:
    '''
    Returns True if the reset was successfull or False if the reset was impossible, usually because not all votes
    for this constituency have been
    '''
    # recalculate aggregate
    function_name = "reset_stimmen_aggregat"
    success = sql_function_to_dict_list(cursor, function_name, (wahl, wknr))[0][function_name]
    if success:
        logger.info(f"Reset aggregates for wahlkreis {wknr} and wahl {wahl}")
    return success

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


def parse_float_de(str: str) -> float or None:
    try:
        return float(str.replace('.', '').replace(',', '.'))
    except:
        return None


def make_unique(dicts: list[dict], key_values: tuple):
    unique_list = []
    key_set = set()
    for d in dicts:
        key = tuple(d[value] for value in key_values)
        if key not in key_set:
            unique_list.append(d)
            key_set.add(key)
    return unique_list


def get_wahljahr(wahl: int) -> int:
    mapping = {20: 2021, 19: 2017}
    return mapping[wahl]


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

def valid_bundesland(land: str):
    return len(land) == 2


def valid_stimme(stimme):
    try:
        x = int(stimme)
    except:
        return False
    return not math.isnan(x) and x >= -1  # -1 is the invalid vote


def valid_uuid(value):
    try:
        UUID(value)
        return True
    except ValueError:
        return False


def valid_admin_token(cursor: psycopg.cursor, wahl: int, wknr: int, token: str):
    query = f"SELECT * FROM admin_token t, wahlkreis wk WHERE t.token = '{token}' AND t.wahlkreis = wk.wkid AND wk.wahl = {wahl} AND wk.nummer = {wknr} AND t.gueltig"
    res = cursor.execute(query).fetchall()
    return len(res) == 1


def generate_wahl_token(cursor: psycopg.cursor, wahl: int, wknr: int) -> UUID:
    wahlkreis_dict = key_dict(cursor, 'wahlkreis', ('wahl', 'nummer'), 'wkid')
    wkid = wahlkreis_dict[(wahl, wknr)]
    token = uuid4()
    statement = f"INSERT INTO wahl_token(wahlkreis, token, gueltig) VALUES ({wkid},'{token}',TRUE)"
    exec_sql_statement(cursor, statement, "GenerateWahlToken.sql")
    return token


def valid_wahl_token(cursor: psycopg.cursor, wahl: int, wknr: int, token: str):
    query = f"SELECT * FROM wahl_token t, wahlkreis wk WHERE t.token = '{token}' AND t.wahlkreis = wk.wkid AND wk.wahl = {wahl} AND wk.nummer = {wknr} AND t.gueltig"
    res = cursor.execute(query).fetchall()
    return len(res) == 1


def make_wahl_token_invalid(cursor: psycopg.cursor, token: str):
    statement = f"UPDATE wahl_token SET gueltig = FALSE WHERE token = '{token}'"
    exec_sql_statement(cursor, statement, "MakeWahlTokenInvalid.sql")


if __name__ == '__main__':
    download_csv(
        'https://raw.githubusercontent.com/sumtxt/ags/master/data-raw'
        '/bundeslaender.csv'
    )
