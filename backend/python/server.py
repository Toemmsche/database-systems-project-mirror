import os

import psycopg
from flask import Flask
from flask import request
import json
from scripts.util import table_to_json
from flask_cors import CORS

app = Flask("db-backend")
CORS(app)

# DATABASE INITIALIZATION HERE

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

@app.route("/api/sitzverteilung/<wahl>")
def get_sitzverteilung(wahl : str):
    # TODO consider 2017 election
    return table_to_json(cursor, "sitzverteilung")

if __name__ == '__main__':
    app.run('localhost', 5000)

# teardown
cursor.close()
conn.close()



