storageHost = window.location.host

module "storage", {'setup': () ->
    stop()
    storage.initializeCache () ->
        start()
    }
    
test "Get existing collection", 3, () ->
    stop()
    storage.getCollection 'Foo', (err, docs) ->
        start()
        ok not err?, "No errors"
        ok docs, "Got documents"
        ok docs.length == 2, "There were two of them"
        
test "Get non-existant collection", 1, () ->
    stop()
    storage.getCollection 'Bar', (err, docs) ->
        start()
        ok err?, "No collection of type Bar"
        
test "Get exisiting document", 3, () ->
    stop()
    storage.getDocument 'Foo', 'foo1', (err, doc) ->
        start()
        ok not err?, "No errors"
        ok doc, "Got a document"
        ok doc.get('_id') == 'foo1', "Document is foo1"
        
test "Get non-existing document of existing type", 1, () ->
    stop()
    storage.getDocument 'Foo', 'baz', (err, doc) ->
        start()
        ok err?, "No document with that ID"
        
test "Get non-exisitng document of non-existing type", 1, () ->
    stop()
    storage.getDocument 'Bar', 'baz', (err, doc) ->
        start()
        ok err?, "No document with type and ID"
                
test "Get existing singleton", 1, () ->
    stop()
    storage.getSingleton 'TestSingleton', (err, doc) ->
        start()
        ok doc?, "Got the singleton"
        
test "Get non-existing singleton", 1, (err, doc) ->
    stop()
    storage.getSingleton 'Foo', (err, doc) ->
        start()
        ok err?, "Couldn't load non-existing singleton"
        
test "Get body of document", 3, (err, doc) ->
    stop()
    storage.getDocument 'Foo', 'foo1', (err, doc) ->
        doc.getBody (err, body) ->
            start()
            ok body?, "Got the body"
            ok body.snapshot.length == 3, "Body has correct size"
            ok body.snapshot[0] == "4", "Body contains the correct data"
            
test "Get collection monitor for Foo", 2, (err, doc) ->
    stop()
    storage.getCollectionMonitor 'Foo', (err, monitor) ->
        start()
        ok monitor?, "Got collection monitor"
        ok monitor.snapshot[0] == 'foo1', "Collection monitor contains correct data"
