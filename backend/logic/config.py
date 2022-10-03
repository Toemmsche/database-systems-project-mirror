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


db_url = "postgres://ucwdnjnjifmwgg:430429ad92ce68ce1ac53a69a66a60ab65c391d44897014a90027d3978500415@ec2-99-81-16-126.eu-west-1.compute.amazonaws.com:5432/dcicjcv08mh5ib"

# Parse database URI
result = urlparse(db_url)
username = result.username
password = result.password
database = result.path[1:]
hostname = result.hostname
port = result.port

conn_string = f"host={hostname} port={port} dbname={database} user={username} password={password}"
