document.addEventListener('DOMContentLoaded', function() {
    var socket = io();

    var tablesList = document.getElementById('tables-list');
    var modal = document.getElementById('modal');
    var modalTitle = document.getElementById('modal-title');
    var modalClose = document.getElementById('modal-close');
    var statusButtons = document.querySelectorAll('.status-btn');

    var currentTable = null;

    socket.on('connect', function() {
        socket.emit('get_status');
    });

    socket.on('status_update', function(data){
        tablesList.innerHTML = '';
        for (var table in data){
            var btn = document.createElement('button');
            btn.className = 'table-btn ' + data[table];
            btn.innerText = table;
            btn.addEventListener('click', function(e){
                currentTable = e.target.innerText;
                modalTitle.innerText = 'Tafel ' + currentTable;
                modal.style.display = 'flex';
            });
            tablesList.appendChild(btn);
        }
    });

    // Wanneer op statusknop geklikt wordt → stuur update
    document.getElementById('status-buttons').addEventListener('click', function(e){
        if (!currentTable || !e.target.dataset.status) return;
        var status = e.target.dataset.status;

        fetch(`/set/${currentTable}/${status}`)
            .then(response => response.text())
            .then(text => {
                console.log(text);
                modal.style.display = 'none';
            })
            .catch(err => console.log('Error: ', err));
    });

    modalClose.addEventListener('click', function(){
        modal.style.display = 'none';
    });
});

