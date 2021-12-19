from waitress import serve
import server
from server import conn

serve(server.app, host='0.0.0.0', port=5000)

# teardown
conn.close()