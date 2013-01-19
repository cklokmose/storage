http = require('http')
shareclient = require('share').client

class DocumentShell
    constructor: (@_doc, @host) ->
        
    getBody: (callback) ->
        if @_doc.bodytype?
            bodytype = @_doc.bodytype
        else
            bodytype = 'json'
        try
            #console.log 'shareclient opening: '+@_doc._id+' with bodytype: '+bodytype+' from host: '+@host
            shareclient.open @_doc._id, bodytype, 'http://'+@host+':8001/channel', (error, doc) -> 
               if error? 
                    console.log Error
                    callback error, null
                else 
                    #console.log doc
                    callback null, doc
        catch error
            console.log error
    
    get: (attr) ->
        return @_doc[attr]

class exports.DocumentCache
    constructor: (@host='localhost', @port=8000) ->
    
    initializeCache: (next) ->
        @docCache = []
        options = 
            'host': @host,
            'port': @port,
            'path': '/Singletons',
            'method': 'GET'

        req = http.request options, (res) =>
            res.setEncoding 'utf8' 
            res.on 'data', (chunk) =>
                @singletons = JSON.parse chunk
                next()

        req.on 'error', (e) =>
            console.log 'problem with request: ' + e.message
        req.end()

    getDocument: (docType, id, callback) ->
        if @docCache.hasOwnProperty(id)
            callback(@docCache[id])
            return

        options = 
            'host': @host,
            'port': @port,
            'path': '/'+docType+'/'+id
            'method': 'GET'
        req = http.request options, (res) =>
            #res.setEncoding 'utf8' 
            res.on 'data', (chunk) =>
                doc = JSON.parse chunk
                @docCache[id] = new DocumentShell(doc, @host)
                callback(@docCache[id])

        req.on 'error', (e) =>
            console.log 'problem with request: ' + e.message
        req.end()
             
    getCollection: (docType, callback) ->
        headers = {
            'Host': @host,
            'Content-Type': 'application/json'
        }

        options = 
            'host': @host,
            'port': @port,
            'path': '/'+docType,
            'method': 'GET'

        results = []
        req = http.request options, (res) =>
            res.setEncoding 'utf8' 
            res.on 'data', (chunk) =>
                docs = JSON.parse chunk
                for doc in docs
                    if not doc.id in @docCache
                        @docCache[doc.id].updateDoc(doc.value)
                    else
                        @docCache[doc.id] = new DocumentShell(doc.value, @host)
                    results.push @docCache[doc.id]
                callback(results)

        req.on 'error', (e) =>
            console.log 'problem with request: ' + e.message
        req.end()
        
    getSingleton: (name, callback) ->
        found = false
        for singleton in @singletons
            if singleton == name
                found = true
        if not found
            callback(new Error("Singleton does not exist"))
            return
        try
            shareclient.open name, 'json', 'http://'+@host+':8001/channel', (error, doc) -> 
        	    if (error) 
        		    callback error, null
        	    else 
        	        callback null, doc
        catch error
            console.log error