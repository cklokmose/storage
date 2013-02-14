cs = require('coffee-script');
express = require('express');
storage = require('..').storage

storageServer = new storage.Storage();
app = express();

storageServer.attachServer(app, {'host': 'localhost', 'port': 5984, 'name': 'storage'}, function(app) {
    storageServer.registerDocument('MyDocument', function(error) {
        console.log(error);
    });
});

app.listen(8000);