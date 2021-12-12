import math
import os

import psycopg
from flask import Flask
from flask import abort
from flask_cors import CORS

from main import init_backend
from util import (
    table_to_json,
    single_result_to_json,
    query_result_to_json,
    models_nat,
)

app = Flask("db-backend")
CORS(app)

# Database initialization
init_backend()

# new database connection
conn = psycopg.connect(
    dbname='wahl',
    user='postgres',
    password=os.environ.get('POSTGRES_PWD'),
    autocommit=True
)

cursor = conn.cursor()


@app.route("/api/")
def sayHello():
    return "Hello World"


@app.route("/api/<wahl>/sitzverteilung")
def get_sitzverteilung(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, "sitzverteilung")


@app.route("/api/<wahl>/mdb/")
def get_mdb(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, "mdb")


@app.route("/api/<wahl>/wahlkreis/<wknr>")
def get_wahlkreisinformation(wahl: str, wknr: str):
    if not models_nat(wahl) or \
            int(wahl) not in [19, 20] or \
            not models_nat(wknr):
        abort(404)
    res = cursor.execute(
        f'SELECT * FROM wahlkreisinformation WHERE nummer = {wknr}'
    ).fetchall()
    if len(res) == 0:
        abort(404)
    return single_result_to_json(cursor, res)


@app.route("/api/<wahl>/wahlkreis/<wknr>/results")
def get_wahlkreis_results(wahl: str, wknr: str):
    if not models_nat(wahl) or \
            int(wahl) not in [19, 20] or \
            not models_nat(wknr):
        abort(404)
    res = cursor.execute(
        f'SELECT * FROM erststimmen_qpartei_wahlkreis_rich WHERE nummer = '
        f'{wknr}'
    ).fetchall()
    return query_result_to_json(cursor, res)


@app.route("/api/<wahl>/wahlkreissieger")
def get_wahlkreissieger(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, 'wahlkreissieger')


if __name__ == '__main__':
    app.run('localhost', 5000)

# teardown
cursor.close()
conn.close()
