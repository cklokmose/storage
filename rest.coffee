class exports.Document
    constructor: (@name, @server) ->
        @server.app.get '/' + @name, (req, res) => 
            @getCollection(req, res)
        @server.app.get '/' + @name + '/:id', (req, res) => 
            @getElement(req, res)
        @server.app.put '/' + @name, (req, res) => 
            @putCollection(req, res)
        @server.app.put '/' + @name, (req, res) => 
            @putElement(req, res)
        @server.app.post '/' + @name, (req, res) => 
            @postCollection(req, res)
        @server.app.post '/' + @name + '/:id', (req, res) => 
            @postElement(req, res)
        @server.app.delete '/' + @name, (req, res) => 
            @deleteCollection(req, res)
        @server.app.delete '/' + @name + '/:id', (req, res) => 
            @deleteElement(req, res)
            
        @server.app.get '/' + @name + '/:id/body', (req, res) =>
            @getBody(req, res)
            
        @server.app.post '/' + @name + '/:id/body', (req, res) =>
            @postBody(req, res)
            
        @server.app.put '/' + @name + '/:id/body', (req, res) =>
            @putBody(req, res)

    getCollection: (req, res) ->
        @server.getCollection @name, (error, result) ->
            if error?
                res.send error, 404
            else
                res.send result

    getElement: (req, res) ->
        if req.query.mode? and req.query.mode == 'live'
            res.sendfile(__dirname+'/live/_view.html')
            return
        @server.getElement req.params.id, @name, (error, result) ->
            if error?
                res.send error, 404
            else
                res.send result            

    putCollection: (req, res) ->
        res.send("PUT to this collection is not supported")
        
    postCollection: (req, res) ->
        try
            @server.postCollection req.body, @name, (result) ->
                res.send result
        catch error
            console.log 'error in post collection: '+error
            res.send error 

    deleteCollection: (req, res) ->
        res.send("DELETE of this collection is not supported")
                    
    #put element             
    putElement: (req, res) ->   
        res.send("PUT to this element is not supported")          
        

    postElement: (req, res) ->
        try
            @server.postElement req.params.id, req.body, @name, (result) ->
                res.send result
        catch e
            console.log 'error in post element: '+error
            res.send e                        

    deleteElement: (req, res) ->
        try
            @server.deleteElement req.params.id, @name, (result) ->
                res.send result
        catch e
            console.log 'error in delete element: '+error
            res.send e 
    
    putBody: (req, res) ->
        res.send("PUT to body is not supported")            

    getBody: (req, res) ->
        try
            #2nd param true indicates that a response is passed 
            #to server - http response is sent from server
            dummyFunc = ()-> 

            @server.getBody req.params.id, @name, dummyFunc , true, res
        catch e
            console.log 'error in get body: '+error
            res.send e

    ###
    #SHOULD BE MOVED TO STORAGE.COFFEE
    ###
    postBody: (req, res) ->
        if req.query['v']?
            version = req.query['v']
        else if req.headers['x-ot-version']?
            version = req.headers['x-ot-version']
        if not version?
            res.send('Error: No version given', 400)
        headers = {}
        headers['content-type'] = 'application/json'
        request = @server.shareREST.request('POST', '/doc/'+req.params.id+'?v='+version, {'host': 'localhost', 'headers': headers})
        request.write(JSON.stringify(req.body))
        request.end()
        request.on 'error', (e) =>
            console.log e.message
            res.send(e.message, 400)
            return
        request.on 'response', (response) =>
            for key, val of response.headers
                res.header(key, val)
            response.on 'data', (chunk) =>
                res.send(chunk, response.statusCode)

class exports.Singleton
    constructor: (@name, @server) ->
        @server.app.get '/' + @name, (req, res) => 
            if req.query.mode? and req.query.mode == 'live'
                res.sendfile(__dirname+'/live/_view.html')
                return
            request = @server.shareREST.request('GET', '/doc/'+@name, {'host': 'localhost'})
            request.end()
            request.on 'response', (response) =>
                for key, val of response.headers
                    res.header(key, val)
                response.on 'data', (chunk) =>
                    res.send(chunk, response.statusCode)
                    
        @server.app.post '/' + @name, (req, res) =>
            if req.query['v']?
                version = req.query['v']
            else if req.headers['x-ot-version']?
                version = req.headers['x-ot-version']
            if not version?
                res.send('Error: No version given', 400)
            headers = {}
            headers['content-type'] = 'application/json'
            request = @server.shareREST.request('POST', '/doc/'+@name+'?v='+version, {'host': 'localhost', 'headers': headers})
            request.write(JSON.stringify(req.body))
            request.end()
            request.on 'error', (e) =>
                console.log e.message
                res.send(e.message, 400)
                return
            request.on 'response', (response) =>
                for key, val of response.headers
                    res.header(key, val)
                response.on 'data', (chunk) =>
                    res.send(chunk, response.statusCode)
                    
        @server.app.put '/' +@name, (req, res) =>
            headers = {}
            headers['content-type'] = 'application/json'
            request = @server.shareREST.request('PUT', '/doc/'+@name, {'host': 'localhost', 'headers': headers})
            request.write(JSON.stringify(req.body))
            request.end()
            request.on 'error', (e) =>
                res.send(e.message, 400)
                return
            request.on 'response', (response) =>
                if response.statusCode == 500
                    res.send('Body already exist', 500)
                    return
                response.on 'data', (chunk) =>
                    res.send(chunk, response.statusCode)