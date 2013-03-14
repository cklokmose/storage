storage
=======

**README IS WORK IN PROGRESS**

Storage is a simple REST-based data model on top of an operational transformation engine.
Storage is designed towards developing multi-surface applications, providing persistance and distributed and concurrent editing.

The core technologies used by Storage is [CouchDB](http://couchdb.apache.org) for persistance and [ShareJS](http://sharejs.org) as the operational transformation engine.

Central concepts
----------------

storage provides a set of server defined typed resources. Resources consists of two parts, a *shell* and a *body*.

 * **shell**: is what you traditionally would expect from a REST resource (see additional details under REST API).
     + GET to http://www.example.com/MyResource returns a list of resources with type MyResource
     + POST to http://www.example.com/MyResource creates a new resources of type MyResource
     + POST to http://www.example.com/MyResource/myresource1 allows setting attributes on the MyResource with id myresource1
 * **body**: every shell contains a body intended for realtime mutable data, this means data where notifications of updates are relevant for other concurrent clients.
     + GET to http://www.example.com/MyResource/myresource1/body will return a snapshot of the current state of the body
     + POST to http://www.example.com/MyResource/myresoirce1/body allows for sending JSON based operational transformations to the body according to the [ShareJS documentation](https://github.com/josephg/ShareJS/wiki).

Besides resources typed with a collection type like _MyResource_ described above, storage provides a __singleton__ resource. A singleton provides a single uniquely named sharejs document that can be accessed with a GET on http://www.example.com/MySingleton

Each collection type has a singleton of e.g. named _MyResourceMonitor_ this singleton is a list of the ids of all resources with type 'MyResource'. This singleton can be used to monitor when new resources of a given type is created.

Client API
---------------------------


###Initializing

Add these script tags:
```html
<script src="/storage/channel/bcsocket.js"></script>
<script src="/storage/share/share.js"></script>
<script src="/storage/share/json.js"></script>
<script src="/storage/client.js"></script>
```

And add this code:
```html
<script>
    storage.initializeCache(function() {
       //Storage is now initialized 
    });
</script>
```

###Get collection

```javascript
storage.getCollection('MyCollection', function(err, shells) {
    //...
});
```

###Get shell

```javascript
storage.getShell('MyCollection', 'myshell1', function(err, doc) {
     //...
});
```

###Get body of a shell

```javascript
shell.getBody(function(err, body) {
     //body is sharejs document
     body.on('remoteop', function(op) {
          //...
     });
});
```

###Get Singleton

```javascript
storage.getSingleton('MySingleton', function(err, singleton) {
     //singleton is a sharejs document
});
```

###Get Collection monitor singleton

```javascript
storage.getCollectionMonitor('MyCollection', function(err, monitor) {
   //monitor is a sharejs document containing a list of shell IDs with type MyCollection
});
```

Server API
----------

The storage server relies on the [express web framework](http://expressjs.com). 

###Minimal storage server

```javascript
cs = require('coffee-script');
express = require('express');
storage = require('storage');

storageServer = new storage.Storage();
app = express();

storageServer.attachServer(app, {'host': 'localhost', 'port': 5984, 'name': 'storage'}, function(app) {
    storageServer.registerDocument('MyDocument', function(error) {
        //You can now get an empty list of shells at http://localhost:8000/MyDocument
    });
});

app.listen(8000);
```

###Register singleton

```javascript
storageServer.registerSingleton("MySingleton"); //NB: Syncronous call, no need or callback
```

REST API
--------
TODO

Node.js client API
------------------
TODO


