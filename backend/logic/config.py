import os

db_config = {
    'dbname': 'wahl',
    'user': 'tom',
    'password': os.environ.get('POSTGRES_PWD')
}

conn_string = f"host=localhost port=5432 dbname=wahl user=tom password=1108"
