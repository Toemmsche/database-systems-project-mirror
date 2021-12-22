from logic.DatabaseInitialization import init_backend

# Database initialization
init_backend()

from waitress import serve
import server
from server import conn_pool

serve(server.app, host='0.0.0.0', port=5000)

# teardown
conn_pool.close()
