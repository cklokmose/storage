http = require 'http'
cs = require 'coffee-script'
util = require 'util'
cradle = require 'cradle'
express = require 'express'
url = require 'url'
udp = require 'dgram'
rest = require './rest'
shareclient = require('share').client

class exports.Storage
    
    constructor: (@bootstrapping = false) ->

    attachServer: (@app= null, dbinfo = {}) ->
        @documents = []
        @singletons = []
        
        if not @app?
            @app = express()
            @app.use (req, res, next) ->
                res.header 'Access-Control-Allow-Origin', '*'
                next()
        @app.use(express.bodyParser())
        
        @app.get '/Types', (req, res) =>
            names = []
            for document in @documents
                names.push document.name
            res.send names
            
        @app.get '/Singletons', (req, res) =>
            names = []
            for singleton in @singletons
                names.push singleton.name
            res.send names
            
        @app.get '/storage/client.js', (req, res) =>
            fs.readFile './client/client.coffee', 'utf-8', (error, data) =>
                try
                    cs = CoffeeScript.compile data
                    res.send cs
                catch error
                    console.log "Failed compiling client.coffee"
                    console.log error
                    res.statusCode = 500
                    res.send {"error":"server error", "reason":"storage server could not compile storage client!"}
        
        dbhost = if dbinfo.host? then dbinfo.host else 'localhost'
        dbport = if dbinfo.port? then dbinfo.port else 5984
        dbname = if dbinfo.name? then dbinfo.name else "document"
        
        @_connectToDb dbhost, dbport, dbname
        @_setupShareJs()
        return @app
 
    _connectToDb: (host, port, name) ->
        @db = new(cradle.Connection)(host, port, {cache: true,raw: false}).database(name)
        
    _setupShareJs: () ->
        @shareApp = express()
        @shareApp.use (req, res, next) ->
            res.header 'Access-Control-Allow-Origin', '*'
            next()
        
        options = { db: { type: 'couchdb', uri: 'http://localhost:5984/notebook-sharejs' }, port: 5984 };
        shareserver.attach(@shareApp, options)
        
        @shareApp.listen(8001)
        console.log('Share running at http://127.0.0.1:8001/')
        @shareClient = shareclient
        @shareREST = http.createClient(8001, 'localhost')

    registerSingleton: (name, validation=null) ->
        singleton = new rest.Singleton(name, this)
        @singletons.push singleton
        
    registerDocument: (name, validation=null) ->
        document = new rest.Document(name, this)
        @documents.push document
        if not validation?
            validation = (newDoc, oldDoc, usrCtx) ->
                return
        
        #To anyone reading this code: Sorry about the ugly hack below!
        viewStr = '(doc) ->\n\tif (doc.type && doc.type == "'+name+'")\n\t\temit(null, doc)'
        
        viewWithName = () ->
            return cs.eval viewStr 
        
        view = viewWithName()
        @db.save '_design/'+name, {
            views: {
                list: {
                    map: view
                }
            }
            validate_doc_update: validation
        }
        
        if not @bootstrapping
            @_registerDocumentMonitor name

    #Register a singleton that will contain a list of all documents of a type 
    _registerDocumentMonitor: (name) ->
        singletonName = name+"Monitor"
        @registerSingleton singletonName
        @_setDocumentNames name, singletonName

    #Get all documents of @param type and save list of doc names in 
    #[DocType]Monitor singleton
    _setDocumentNames: (type, singletonName) ->
        @getCollection type, (results) ->
            nameList = [] 
            for docu in results
                nameList.push docu.value.name
            shareclient.open singletonName, 'json', 'http://localhost:8001/channel', (error, doc) =>
                doc.set nameList, (error, rev) ->
                    if error?
                        console.log error        
    ###
    #REST INTERFACE FOR DATABASE ACCESS
    ###
    getCollection: (name, cb) ->
        @db.view(
            name+'/list',
            (error, result) =>
                if error?
                    console.log error + "No documents of type "+name
                    throw error
                cb result
        ) 

    getElement: (id, name, cb) ->
        @db.get id, (error, doc) =>
                if (error || doc.type != name)
                    console.log name+" does not exist"
                    throw error?
                else
                    cb doc

    postCollection: (collectionBody, name, cb) ->
        doc = collectionBody
        body = null
        bodytype = doc.bodytype ? 'json'
        if doc.body?
            body = doc.body
            delete doc.body
        doc.type = name
        console.log 'posting '+doc.type
        @db.save doc, (err, res) =>
            if err?
                throw err
            else
                @db.get res.id, (err, savedDoc) =>
                    if err?
                        throw err
                    else
                        @_createBody bodytype, res.id, (err) =>
                            if err?
                                throw err
                            else
                                if body?
                                    @_insertInBody bodytype, res.id, body, (err) =>
                                        if err?
                                            throw err
                                        cb savedDoc  
                                else
                                    cb savedDoc 

    postElement: (id, body, name, cb) ->
        @db.get id, (error, doc) =>
            if (error || doc.type != name)
                throw error
            docChanges = body
            for key, value of docChanges
                doc[key] = value
            @db.save doc, (err, res) =>
                if err?
                    throw err
                else
                    @db.get id, (err, changedDoc) =>
                        if err?
                            throw err
                        else
                            cb changedDoc

    deleteElement: (id, mame, cb) ->
        @db.get id, (error, doc) =>
            if (error? || doc.type != name)
                throw error
            @db.remove doc._id, doc._rev, (error, res1) =>
                if error?
                    throw error
                else
                    cb "Success"

    #optional parameter restReq - uses responseCallBack to
    #send information about share rest call status
    getBody: (id, name, cb, restReq=false, res) ->
        @db.get id, (error, doc) =>
                if (error? || doc.type != name)
                    throw error
                else
                    request = @shareREST.request('GET', '/doc/'+id, {'host': 'localhost'});
                    request.end()
                    request.on 'response', (response) =>
                        if restReq
                            for key, val of response.headers
                                res.header(key, val)
                            response.on 'data', (chunk) =>
                                res.send(chunk, response.statusCode)
                            return null
                        else
                            response.on 'data', (chunk) =>
                                cb chunk
                    

    ###
    #MISSING IMPLEMENTATION OF POSTBODY - STILL IN REST.COFFEE
    ###
    _createBody: (bodytype, id, cb) ->
        headers = {}
        headers['content-type'] = 'application/json'
        headers['X-OT-version'] = '0'
        request = @shareREST.request("PUT", "/doc/" + id,"host": "localhost", "headers": headers)

        request.write JSON.stringify({"type": bodytype})
        request.end()
        request.on "error", (e) ->
           cb new Error(e.message)
        request.on "response", (response) ->
            if response.statusCode is 500
               cb new Error("Body already exist")
               return
            response.on "data", (chunk) ->
                cb null

    _insertInBody: (bodytype, id, body_data, cb) ->
        headers = {} 
        headers['content-type'] = 'application/json';
        
        version = 0
        request = @shareREST.request("POST", "/doc/" + id + "?v=" + version, {"host": "localhost", "headers": headers})

        if bodytype == 'json'
            op = [{"p": [],"oi": body_data }]
        else if bodytype == 'text'
            op = [{"p":0,"i":body_data}]
        request.write JSON.stringify(op)    
        request.end()
        request.on "error", (e) ->
            console.log('error')
            cb new Error(e.message)
        request.on "response", (response) ->
            if response.statusCode is 500
                cb new Error("Body already exist")
                return
            response.on "data", (chunk) ->
                cb null


