from flask import Flask, abort, request
from flask_cors import CORS
from psycopg_pool import ConnectionPool

from logic.config import conn_string
from logic.metrics import *
from logic.util import *

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
            reset_aggregates(cursor, int(wahl), int(wknr))
        return table_to_json(cursor, 'wahlkreisinformation', wahl=wahl, wk_nummer=wknr, single=True)


@app.route("/api/<wahl>/wahlkreis/<wknr>/stimmen", methods=['GET'])
def get_wahlkreisergebnis_stimmen(wahl: str, wknr: str):
    if not valid_wahl(wahl) or not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            reset_aggregates(cursor, int(wahl), int(wknr))
        return table_to_json(cursor, 'stimmen_qpartei_wahlkreis', wahl=wahl, wk_nummer=wknr)


@app.route("/api/<wahl>/zweitstimmen_aggregiert", methods=['POST'])
def get_zweitstimmen(wahl: str):
    wahlkreise = request.json
    if not valid_wahl(wahl) or any([not valid_wahlkreis(wknr) for wknr in wahlkreise]):
        abort(404)

    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # if specified, reset aggregates
        if request.args.get('einzelstimmen') == 'true':
            for wknr in wahlkreise:
                reset_aggregates(cursor, int(wahl), int(wknr))
        strIds = ', '.join(map(str, wahlkreise))
        return table_to_json(
            cursor,
            f"zweitstimmen_aggregiert({wahl}, '{{ {strIds} }}')"
        )  # postgres integer array initializer


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


@app.route(
    "/api/<wahl>/stat/aqvergleich"
    "", methods=['GET']
)
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
        return table_to_json(cursor, 'stimmen_qpartei_wahlkreis', wahl=wahl)


# Voting is only available for the latest election
@app.route("/api/20/wahlkreis/<wknr>/stimmzettel", methods=['GET'])
def get_stimmzettel(wknr: str):
    if not valid_wahlkreis(wknr):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return table_to_json(cursor, 'stimmzettel_2021', wk_nummer=wknr)


@app.route("/api/20/wahlkreis/<wknr>/wahl_token", methods=['POST'])
def get_wahl_token(wknr: str):
    if not valid_wahlkreis(wknr):
        abort(404)

    with conn_pool.connection() as conn, conn.cursor() as cursor:
        try:
            data = request.json
            if data is None:
                raise "No json content type set"
        except:
            err_str = f"Bad token request: {request.data}"
            logger.error(err_str)
            abort(400)
        if 'token' not in data:
            err_str = f"Missing admin token"
            logger.error(err_str)
            abort(401)
        token = data['token']
        if valid_uuid(token) and valid_admin_token(cursor, 20, int(wknr), token):
            # Generate new wahl token
            new_token = generate_wahl_token(cursor, 20, int(wknr))
            return {'token': str(new_token)}
        else:
            err_str = f"Invalid admin token for wahlkreis {wknr}: {token}"
            logger.error(err_str)
            abort(401)


@app.route("/api/20/wahlkreis/<wknr>/stimmabgabe", methods=['POST'])
def cast_vote(wknr: str):
    if not valid_wahlkreis(wknr):
        abort(404)

    with conn_pool.connection() as conn, conn.cursor() as cursor:
        # Verify vote validity
        stimmzettel = table_to_dict_list(cursor, 'stimmzettel_2021', wk_nummer=wknr)
        try:
            stimmen = request.json
            if stimmen is None:
                raise "No json content type set"
        except:
            err_str = f"Bad vote request: {request.data}"
            logger.error(err_str)
            abort(400)
        if 'token' not in stimmen:
            err_str = f"Missing wahl token"
            logger.error(err_str)
            abort(401)
        token = stimmen['token']
        # prevent SQL injection via token string
        if valid_uuid(token) and valid_wahl_token(cursor, 20, int(wknr), token):
            make_wahl_token_invalid(cursor, token)
        else:
            err_str = f"Invalid wahl token for wahlkreis {wknr}: {token}"
            logger.error(err_str)
            abort(401)
        if 'erststimme' in stimmen:
            erststimme = stimmen['erststimme']
            # Check for 'ungueltig' vote
            if erststimme == -1:
                load_into_db(cursor, [(1, int(wknr))], "ungueltige_stimme")
                logger.info(f"Received 'ungueltig' first vote in {wknr}")
            else:
                legal_erststimmen = list(map(lambda e: e['kandidatur'], stimmzettel))
                if valid_stimme(erststimme) and erststimme in legal_erststimmen:
                    load_into_db(cursor, [(erststimme,)], 'erststimme', )
                    logger.info(f"Received first vote for {erststimme} in {wknr}")
                else:
                    err_str = f"Invalid first vote for wahlkreis {wknr}: {str(erststimme)}"
                    logger.error(err_str)
        if 'zweitstimme' in stimmen:
            zweitstimme = stimmen['zweitstimme']
            # Check for 'ungueltig' vote
            if zweitstimme == -1:
                load_into_db(cursor, [(2, int(wknr))], "ungueltige_stimme")
                logger.info(f"Received 'ungueltig' second vote in {wknr}")
            else:
                legal_zweitstimmen = list(map(lambda e: e['liste'], stimmzettel))
                if valid_stimme(zweitstimme) and zweitstimme in legal_zweitstimmen:
                    load_into_db(cursor, [(zweitstimme, int(wknr))], 'zweitstimme')
                    logger.info(f"Received second vote for {zweitstimme} in {wknr}")
                else:
                    err_str = f"Invalid second vote for wahlkreis {wknr}: {str(zweitstimme)}"
                    logger.error(err_str)
        return 'processed\n'


@app.route("/api/<wahl>/rangliste", methods=['GET'])
def get_metriken(wahl: str):
    if not valid_wahl(wahl):
        abort(404)
    return all_metrics_to_json(int(wahl))


@app.route("/api/<wahl>/rangliste/<metrik>", methods=['GET'])
def get_metrik(wahl: str, metrik: str):
    if not valid_wahl(wahl) or not valid_metrik(metrik):
        abort(404)
    with conn_pool.connection() as conn, conn.cursor() as cursor:
        return get_wahlkreise_ranked_by_metric(cursor, int(wahl), metrik)


if __name__ == '__main__':
    app.run('localhost', 5000)

    # teardown
    conn_pool.close()
