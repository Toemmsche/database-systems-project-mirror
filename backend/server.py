import psycopg
from flask import Flask, abort, request
from flask_cors import CORS

from logic.DatabaseInitialization import db_config
from logic.DatabaseInitialization import init_backend
from logic.util import (
    valid_wahl,
    valid_wahlkreis,
    table_to_json,
    models_nat,
    reset_aggregates,
    exec_script_from_file
)

app = Flask("db-backend")
CORS(app)

# Database initialization
init_backend()

# new database connection
conn = psycopg.connect(
    **db_config,
    autocommit=True
)

cursor = conn.cursor()


@app.route("/api/")
def sayHello():
    return "Hello World"


@app.route("/api/<wahl>/sitzverteilung")
def get_sitzverteilung(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    return table_to_json(cursor, "sitzverteilung", wahl=wahl)


@app.route("/api/<wahl>/mdb/")
def get_mdb(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    return table_to_json(cursor, "mdb", wahl=wahl)


@app.route("/api/<wahl>/wahlkreis/<wknr>")
def get_wahlkreisinformation(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    exec_script_from_file(cursor, 'sql/queries/WahlkreisUebersicht_Refresh.sql')
    # if specified, reset aggregates
    if request.args.get('einzelstimmen') == 'true':
        reset_aggregates(cursor, wahl, wknr)
    return table_to_json(cursor, 'wahlkreisinformation', wahl=wahl, wahlkreis=wknr, single=True)


@app.route("/api/<wahl>/wahlkreis/<wknr>/results")
def get_wahlkreis_results(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    exec_script_from_file(cursor, 'sql/queries/WahlkreisUebersicht_Refresh.sql')
    return table_to_json(cursor, 'erststimmen_qpartei_wahlkreis_rich', wahl=wahl, wahlkreis=wknr)


@app.route("/api/<wahl>/wahlkreissieger")
def get_wahlkreissieger(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, 'wahlkreissieger')


@app.route("/api/<wahl>/ueberhang")
def get_ueberhang(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, 'ueberhang_qpartei_bundesland')


@app.route("/api/<wahl>/stat/knapp")
def get_knapp(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, 'knappste_siege_oder_niederlagen')


@app.route("/api/<wahl>/ostenergebnis")
def get_osten_ergebnis(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    return table_to_json(cursor, 'zweitstimmen_qpartei_osten')


if __name__ == '__main__':
    app.run('localhost', 5000)

# teardown
cursor.close()
conn.close()
