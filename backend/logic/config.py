import os

db_config = {
    'dbname': 'wahl',
    'user': 'postgres',
    'password': os.environ.get('POSTGRES_PWD')
}

conn_string = "host=localhost port=5432 dbname=wahl user=postgres password=1108"
