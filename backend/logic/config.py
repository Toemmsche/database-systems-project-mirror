import os
from urllib.parse import urlparse

heroku = False
if 'DYNO' in os.environ:
    heroku = True
    print("Detected heroku deployment")

load_all_einzelstimmen = False
if 'EINZELSTIMMEN' in os.environ:
    load_all_einzelstimmen = True
    print("Will load all Einzelstimmen")


# Parse database URI
result = urlparse(os.environ.get('DATABASE_URL'))
username = result.username
password = result.password
database = result.path[1:]
hostname = result.hostname
port = result.port

conn_string = f"host={hostname} port={port} dbname={database} user={username} password={password}"
