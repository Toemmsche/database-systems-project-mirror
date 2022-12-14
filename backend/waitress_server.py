from logic.Initialization import init_backend

# Database initialization
init_backend()

from waitress import serve
import server
from server import conn_pool
import logging

# adjust logging config
logger = logging.getLogger('waitress')
logger.setLevel(logging.INFO)

serve(server.app, host='0.0.0.0', port=5000)

# teardown
conn_pool.close()
