import time

from flask import Flask, abort, request, current_app, g as app_ctx
from flask_cors import CORS
from psycopg_pool import ConnectionPool

from logic.config import conn_string
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
# init_backend()

# new database connection

conn_pool = ConnectionPool(conn_string,
                           min_size=6)


@app.before_request
def logging_before():
    # Store the start time for the request
    app_ctx.start_time = time.perf_counter()


@app.after_request
def logging_after(response):
    # Get total time in milliseconds
    total_time = time.perf_counter() - app_ctx.start_time
    time_in_ms = int(total_time * 1000)
    # Log the time taken for the endpoint
    current_app.logger.info('PROCESSING TIME: %s ms %s %s %s', time_in_ms, request.method, request.path,
                            dict(request.args))
    return response


@app.route("/api/")
def sayHello():
    return "Hello World"


@app.route("/api/<wahl>/sitzverteilung")
def get_sitzverteilung(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, "sitzverteilung", wahl=wahl)


@app.route("/api/<wahl>/mdb/")
def get_mdb(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, "mitglieder_bundestag", wahl=wahl)


@app.route("/api/<wahl>/wahlkreis/<wknr>")
def get_wahlkreisinformation(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:  # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'wahlkreisinformation', wahl=wahl, wk_nummer=wknr, single=True)


@app.route("/api/<wahl>/wahlkreis/<wknr>/erststimmen")
def get_wahlkreisergebnis_erststimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'erststimmen_qpartei_wahlkreis_rich', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/wahlkreis/<wknr>/zweitstimmen")
def get_wahlkreisergebnis_zweitstimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'zweitstimmen_qpartei_wahlkreis_rich', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/wahlkreissieger")
def get_wahlkreissieger(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'wahlkreissieger', wahl=wahl)


@app.route("/api/<wahl>/ueberhang")
def get_ueberhang(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'ueberhang_qpartei_bundesland', wahl=wahl)


@app.route("/api/<wahl>/stat/knapp")
def get_knapp(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'knappste_siege_oder_niederlagen', wahl=wahl)


@app.route("/api/<wahl>/ostenergebnis")
def get_osten_ergebnis(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'zweitstimmen_qpartei_osten', wahl=wahl)


@app.route("/api/<wahl>/karte")
def get_karte(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'begrenzungen', wahl=wahl)


@app.route("/api/<wahl>/wahlkreisergebnisse")
def get_wahlkreisergebnisse(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'stimmen_qpartei_wahlkreis_rich', wahl=wahl)


if __name__ == '__main__':
    app.run('localhost', 5000)

    # teardown
    conn_pool.close()
