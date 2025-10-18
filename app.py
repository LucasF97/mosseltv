from flask import Flask, render_template, abort
from flask_socketio import SocketIO, emit

# start flask-app en websocket
app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# tafel status (voorlopig dict, later JSON-bestand)
# TODO: sla status op in een bestand ipv memory
tables = {i: "idle" for i in range(1, 27)}

# index-pagina (normaal niet gebruikt)
# TODO: voeg hier links toe naar de paginas die wel gebruikt worden
@app.route("/")
def index():
    return "MosselTV server draait!"

# Display (TV) met tafeloverzicht
@app.route("/display")
def display():
    return render_template('display.html')

# Manager interface
@app.route("/manager")
def manager():
    return render_template('manager.html')

# manager interface met lijst van tafels
@app.route("/manager_list")
def manager_list():
    return render_template('manager_list.html')

# status instellen (primitief)
# TODO: deftig
@app.route("/set/<int:table>/<status>")
def set_status(table, status):
    if table not in tables:
        return abort(404, description=f"Tafel {table} bestaat niet")
    if status not in ["idle", "almost_ready", "ready"]:
        return abort(400, description="ongeldige status")
    tables[table] = status
    socketio.emit('status_update', tables)
    return f"Tafel {table} status gewijzigd naar {status}"

# update status bij request
@socketio.on('get_status')
def handle_get_status():
    emit('status_update', tables)

# start server (voorlopig enkel op loopback adres)
# TODO: laat ook andere (lokale) adressen toe
if __name__ == "__main__":
    import eventlet
    import eventlet.wsgi
    socketio.run(app, host="127.0.0.1", port=5000, debug=True)
