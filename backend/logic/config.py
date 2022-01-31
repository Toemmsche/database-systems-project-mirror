import os

db_config = {
    'dbname': os.environ.get('POSTGRES_DB') if 'POSTGRES_DB' in os.environ else 'wahl',
    'user': os.environ.get('POSTGRES_USER') if 'POSTGRES_USER' in os.environ else 'postgres',
    'password': os.environ.get('POSTGRES_PWD')
}

print(os.environ.get('DATABASE_URI'))
print(os.environ.get('DATABASE_URL'))
conn_string = f"host=localhost port=5432 dbname={db_config['dbname']} user={db_config['user']} password={db_config['password']}" if os.environ.get('DATABASE_URI') is None else None # TODO
