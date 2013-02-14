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

Browserbased javascript API
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

REST API
--------

Server API
----------

Node.js client API
------------------



