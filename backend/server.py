import time
from flask import Flask, abort, request, current_app, g as app_ctx
from flask_cors import CORS
from psycopg_pool import ConnectionPool

from logic.config import conn_string
from logic.util import (
    valid_wahl,
    valid_wahlkreis,
    valid_stimme,
    table_to_json,
    models_nat,
    reset_aggregates,
    exec_script_from_file,
    table_to_dict_list,
    load_into_db, logger,
    valid_token,
    make_token_invalid, valid_uuid
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


@app.route("/api/<wahl>/wahlkreis", methods=["GET"])
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


@app.route("/api/<wahl>/wahlkreis/<wknr>/stimmen", methods=['GET'])
def get_wahlkreisergebnis_erststimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, wahl, wknr)
        return table_to_json(cursor, 'stimmen_qpartei_wahlkreis_rich', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/wahlkreissieger", methods=['GET'])
def get_wahlkreissieger(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'wahlkreissieger', wahl=wahl)


@app.route("/api/<wahl>/stat/ueberhang", methods=['GET'])
def get_ueberhang(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'ueberhang_qpartei_bundesland', wahl=wahl)


@app.route("/api/<wahl>/stat/knapp", methods=['GET'])
def get_knapp(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'knappste_siege_oder_niederlagen', wahl=wahl)


@app.route("/api/<wahl>/stat/ostenergebnis", methods=['GET'])
def get_osten_ergebnis(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'zweitstimmen_qpartei_osten', wahl=wahl)


@app.route("/api/<wahl>/stat/aqvergleich"
           "", methods=['GET'])
def get_aq_vergleich(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'zweitstimmen_qpartei_aq_hoch_vs_niedrig', wahl=wahl)


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

@app.route("/api/20/wahlkreis/<wknr>/stimmabgabe", methods=['POST'])
def cast_vote(wknr: str):
    if not valid_wahlkreis(wknr):
        abort(404)

    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # Verify vote validity
        stimmzettel = table_to_dict_list(cursor, 'stimmzettel_2021', wk_nummer=wknr)
        try:
            stimmen = request.json
            if 'token' not in stimmen:
                err_str = f"Token missing"
                logger.error(err_str)
                abort(401)

            token = stimmen['token']
            # prevent SQL injection via token string
            # this check should be performed by the frontend as well but we want to make sure
            if valid_uuid(token) and valid_token(cursor, 20, int(wknr), token):
                make_token_invalid(cursor, token)
            else:
                err_str = f"Invalid token for wahlkreis {wknr}: {token}"
                logger.error(err_str)
                abort(401)
            if 'erststimme' in stimmen:
                erststimme = stimmen['erststimme']
                legalErststimmen = list(map(lambda e: e['kandidatur'], stimmzettel))
                if valid_stimme(erststimme) and erststimme in legalErststimmen:
                    load_into_db(cursor, [(erststimme,)], 'erststimme', )
                    logger.info(f"Received first vote for {erststimme} in {wknr}")
                else:
                    err_str = f"Invalid first vote for wahlkreis {wknr}: {str(erststimme)}"
                    logger.error(err_str)
            if 'zweitstimme' in stimmen:
                zweitstimme = stimmen['zweitstimme']
                legalZweitstimmen = list(map(lambda e: e['liste'], stimmzettel))
                if valid_stimme(zweitstimme) and zweitstimme in legalZweitstimmen:
                    load_into_db(cursor, [(zweitstimme, int(wknr))], 'zweitstimme')
                    logger.info(f"Received second vote for {zweitstimme} in {wknr}")
                else:
                    err_str = f"Invalid second vote for wahlkreis {wknr}: {str(zweitstimme)}"
                    logger.error(err_str)
            return 'processed\n'
        except:
            err_str = f"Bad vote: {request.data}"
            logger.error(err_str)
            abort(400)


if __name__ == '__main__':
    app.run('localhost', 5000)

    # teardown
    conn_pool.close()
