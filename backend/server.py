import time

from flask import Flask, abort, request, current_app, g as app_ctx
from flask_cors import CORS
from psycopg_pool import ConnectionPool

from logic.config import conn_string
from logic.util import (
    valid_wahl,
    valid_wahlkreis,
    table_to_json,
    models_nat,
    reset_aggregates,
    exec_script_from_file,
    table_to_dict_list,
    load_into_db, logger

)

app = Flask("db-backend")
CORS(app)

# new database connection pool
conn_pool = ConnectionPool(conn_string)


@app.route("/api/", methods=['GET'])
def sayHello():
    return "Hello World"


@app.route("/api/<wahl>/sitzverteilung", methods=['GET'])
def get_sitzverteilung(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, "sitzverteilung", wahl=wahl)


@app.route("/api/<wahl>/mdb/", methods=['GET'])
def get_mdb(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, "mitglieder_bundestag", wahl=wahl)


@app.route("/api/<wahl>/wahlkreis", methods= ["GET"])
def get_wahlkreise(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'wahlkreisinformation', wahl=wahl)


@app.route("/api/<wahl>/wahlkreis/<wknr>", methods=['GET'])
def get_wahlkreisinformation(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:  # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'wahlkreisinformation', wahl=wahl, wk_nummer=wknr, single=True)


@app.route("/api/<wahl>/wahlkreis/<wknr>/erststimmen", methods=['GET'])
def get_wahlkreisergebnis_erststimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'erststimmen_qpartei_wahlkreis_rich', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/wahlkreis/<wknr>/zweitstimmen", methods=['GET'])
def get_wahlkreisergebnis_zweitstimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'zweitstimmen_qpartei_wahlkreis_rich', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/wahlkreissieger", methods=['GET'])
def get_wahlkreissieger(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'wahlkreissieger', wahl=wahl)


@app.route("/api/<wahl>/ueberhang", methods=['GET'])
def get_ueberhang(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'ueberhang_qpartei_bundesland', wahl=wahl)


@app.route("/api/<wahl>/stat/knapp", methods=['GET'])
def get_knapp(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'knappste_siege_oder_niederlagen', wahl=wahl)


@app.route("/api/<wahl>/ostenergebnis", methods=['GET'])
def get_osten_ergebnis(wahl: str):
    if not models_nat(wahl) or int(wahl) not in [19, 20]:
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'zweitstimmen_qpartei_osten', wahl=wahl)


@app.route("/api/<wahl>/karte", methods=['GET'])
def get_karte(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'begrenzungen', wahl=wahl)


@app.route("/api/<wahl>/wahlkreisergebnisse", methods=['GET'])
def get_wahlkreisergebnisse(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'stimmen_qpartei_wahlkreis_rich', wahl=wahl)


# Voting is only available for the latest election
@app.route("/api/20/wahlkreis/<wknr>/stimmzettel", methods=['GET'])
def get_stimmzettel(wknr: str):
    if not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'stimmzettel_2021', wk_nummer=wknr)


@app.route("/api/20/wahlkreis/<wknr>/stimmenabgabe", methods=['POST'])
def cast_vote(wknr: str, ):
    if not valid_wahlkreis(wknr):
        abort(404)

    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # Verify vode validity
        stimmzettel = table_to_dict_list(cursor, 'stimmzettel_2021', wk_nummer=wknr)
        stimmen = request.json
        if 'erststimme' in stimmen:
            erststimme = stimmen['erststimme']
            legalErststimmen = list(map(lambda e: e['kandidatur'], stimmzettel))
            if erststimme in legalErststimmen:
                load_into_db(cursor, [(erststimme,)], 'erststimme', )
                logger.info(f"Cast 'erststimme' for {erststimme} in {wknr}")
        if 'zweitstimme' in stimmen:
            zweitstimme = stimmen['zweitstimme']
            legalZweitstimmen = list(map(lambda e: e['liste'], stimmzettel))
            if zweitstimme in legalZweitstimmen:
                load_into_db(cursor, [(zweitstimme, int(wknr))], 'zweitstimme')
                logger.info(f"Cast 'zweitstimme' for {zweitstimme} in {wknr}")
    return 'success'


if __name__ == '__main__':
    app.run('localhost', 5000)

    # teardown
    conn_pool.close()
