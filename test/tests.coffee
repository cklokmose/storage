storageHost = window.location.host

module "storage", {'setup': () ->
    storage.initializeCache()
    }
    
asyncTest "Get existing collection", 3, () ->
    storage.getCollection 'Foo', (err, docs) ->
        start()
        ok not err?, "No errors"
        ok docs, "Got documents"
        ok docs.length == 2, "There were two of them"
        
asyncTest "Get non-existant collection", 1, () ->
    storage.getCollection 'Bar', (err, docs) ->
        start()
        ok err?, "No collection of type Bar"
        
asyncTest "Get exisiting document", 3, () ->
    storage.getDocument 'Foo', 'foo1', (err, doc) ->
        start()
        ok not err?, "No errors"
        ok doc, "Got a document"
        ok doc.get('_id') == 'foo1', "Document is foo1"
        
asyncTest "Get non-existing document of existing type", 1, () ->
    storage.getDocument 'Foo', 'baz', (err, doc) ->
        start()
        ok err?, "No document with that ID"
        
asyncTest "Get non-exisitng document of non-existing type", 1, () ->
    storage.getDocument 'Bar', 'baz', (err, doc) ->
        start()
        ok err?, "No document with type and ID"
        
