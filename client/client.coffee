class Shell
    
    constructor: (@_doc) ->
        @callbacks = []
        @body = null
        
    _callCallbacks: (error, body) ->
        for callback in @callbacks
            callback error, body
        @callbacks = []
    
    getBody: (callback) ->
        if @body?
            callback null, @body
        if @_doc.bodytype?
            bodytype = @_doc.bodytype
        else
            bodytype = 'json'
        if @callbacks.length == 0
            @callbacks = [callback]
            try
                sharejs.open @_doc._id, bodytype, 'http://'+window.location.hostname+':8001/channel', (error, doc) => 
            	    if (error) 
            		    @_callCallbacks error, null
            	    else
            	        @body = doc
            	        @_callCallbacks null, doc
            catch error
                @_callCallbacks error, null
        else
            @callbacks.push callback
    
    get: (attr) ->
        return @_doc[attr]

class Storage
    initializeCache: (cb, @prefix="") ->
        @docCache = {}
        _getDocumentCallbacks = {}
        _getCollectionCallbacks = {}
        _getSingletonCallbacks = {}
        @singletons = []
        $.get @prefix + 'Singletons', (singletons) =>
            @singletons = singletons
            cb()
            
    _callCallbacksNoError: (callbacks, value) ->
        for callback in callbacks
            callback null, value
            
    _callCallbacksWithError: (callbacks, error, value) ->
        for callback in callbacks
            callback error, value
            
    _get: (url, cb) ->
        $.ajax {
            'url': url,
            'type': 'GET',
            'success': (data) -> 
                cb null, data
            ,
            'error': (error) ->
                cb error, null
        }
    
    _getDocumentCallbacks = {}
    getShell: (docType, id, callback) ->
        if @docCache.hasOwnProperty id
            callback @docCache[id]
            return
        if not _getDocumentCallbacks[id] or _getDocumentCallbacks[id].length == 0
            _getDocumentCallbacks[id] = [callback]
            
            @_get @prefix + docType + '/' + id, (error, doc) =>
                if error?
                    @_callCallbacksWithError _getDocumentCallbacks[id], error, null
                else
                    @docCache[id] = new Shell(doc)
                    @_callCallbacksNoError _getDocumentCallbacks[id], @docCache[id]
                _getDocumentCallbacks[id] = []
        else
            _getDocumentCallbacks[id].push callback
             
    _getCollectionCallbacks = {}
    getCollection: (docType, callback) ->
        if not _getCollectionCallbacks[docType]? or _getCollectionCallbacks[docType].length == 0
            _getCollectionCallbacks[docType] = [callback]
            @_get @prefix + docType, (error, docs) =>
                if error?
                    @_callCallbacksWithError _getCollectionCallbacks[docType], error, null
                else
                    results = []
                    for doc in docs
                        if not doc.id in @docCache
                            @docCache[doc.id].updateDoc(doc.value)
                        else
                            @docCache[doc.id] = new Shell(doc.value)
                        results.push @docCache[doc.id]
                    @_callCallbacksNoError _getCollectionCallbacks[docType], results
                _getCollectionCallbacks[docType] = []
        else
            _getCollectionCallbacks[docType].push callback
            
    getCollectionMonitor: (docType, callback) ->
        @getSingleton docType + 'Monitor', (error, doc) =>
            callback error, doc
    
    
    _getSingletonCallbacks = {}
    getSingleton: (name, callback) ->
        found = false
        for singleton in @singletons
            if singleton == name
                found = true
        if not found
            callback(new Error("Singleton does not exist"))
            return
        if not _getSingletonCallbacks[name]? or _getSingletonCallbacks[name].length == 0
            _getSingletonCallbacks[name] = [callback]
            try
                sharejs.open name, 'json', 'http://'+window.location.hostname+':8001/channel', (error, doc) => 
                    if (error) 
                        @_callCallbacksWithError _getSingletonCallbacks[name], error, null
                    else
                        @_callCallbacksWithError _getSingletonCallbacks[name], null, doc
                    _getSingletonCallbacks[name] = []
            catch error
                @_callCallbacksWithError _getSingletonCallbacks, error, null
                _getSingletonCallbacks[name] = []
        else
            _getSingletonCallbacks[name].push callback
            
window.storage = new Storage()