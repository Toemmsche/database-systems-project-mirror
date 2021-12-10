import os

import psycopg
from flask import Flask
from flask_cors import CORS

from backend.python.main import init_backend
from backend.python.util import table_to_json

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
    # TODO consider 2017 election
    return table_to_json(cursor, "sitzverteilung")

@app.route("/api/<wahl>/mdb/")
def get_mdb(wahl: str):
    # TODO consider 2017 election
    return table_to_json(cursor, "mdb")


if __name__ == '__main__':
    app.run('localhost', 5000)

# teardown
cursor.close()
conn.close()
