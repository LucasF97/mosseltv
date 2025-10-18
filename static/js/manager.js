var socket = io();

var tableSelect = document.getElementById('table-select');
var statusSelect = document.getElementById('status-select');
var btn = document.getElementById('set-status-btn');
var msg = document.getElementById('message');

// vul dropdown met aantal tafels
socket.on('connect', function(){
	socket.emit('get_status');
});

// ontvang status
socket.on('status_update', function(data){
	console.log('Status update received: ', data);
	tableSelect.innerHTML = '';
	for (var table in data){
		var opt = document.createElement('option');
		opt.value = table;
		opt.innerText = table;
		tableSelect.appendChild(opt);
	}
});

// bevestigen -> update verzenden
btn.addEventListener('click', function(){
	var table = tableSelect.value;
	var status = statusSelect.value;

	fetch(`/set/${table}/${status}`)
		.then(response => response.text())
		.then(text => { msg.innerText = text; })
		.catch(err => { msg.innerText = 'Error: ' + err; });
});
