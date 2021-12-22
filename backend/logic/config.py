import os

db_config = {
    'dbname': 'wahl',
    'user': 'tom',
    'password': os.environ.get('POSTGRES_PWD')
}

conn_string = f"host=localhost port=5432 dbname=wahl user=tom password=1108"


"""gunicorn (with logging) * 6 at n = 100 t = 1
rps = 210
avg = 33

postgrest  at n = 100 t = 1
rps= 215
avg = 33

postgrest at n = 200 t = 1
rps = 225
avg = 450

gunicorn (with logging) * 6 at n = 200 t = 1
rps = 250
avg = 380

gunicorn (with logging) * 12 at n = 200 t = 1
rps = 290
avg = 240

gunicorn (with logging) * 12 at n = 500 t = 1
rps = 290
avg = 1300

postgrest at n = 500 t = 1
rps = 220
avg = 1800
"""