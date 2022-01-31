import os
from urllib.parse import urlparse

# Parse database URI
result = urlparse(os.environ.get('DATABASE_URI'))
username = result.username
password = result.password
database = result.path[1:]
hostname = result.hostname
port = result.port

conn_string = f"host={hostname} port={port} dbname={database} user={username} password={password}"
