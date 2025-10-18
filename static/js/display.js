var socket = io();

function updateTables(data){
	var container = document.getElementById('tables');
	container.innerHTML = '';
	for (var table in data){
	    var div = document.createElement('div');
	    div.className = 'table ' + data[table];
	    div.innerText = table
	    container.appendChild(div);
	}
}
// vraag bij verbinding meteen status
socket.on('connect', function(){socket.emit('get_status');});

// ontvang status updates
socket.on('status_update', function(data){updateTables(data);});
