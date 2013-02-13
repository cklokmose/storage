cradle = require 'cradle'
express = require 'express'
storage = require('..').storage
testData= require './test_data'
http = require 'http'
async = require 'async'

clearDB = (db, cb) ->
    db.destroy (err, res) ->
        if err?
            console.log "Database missing (or couchdb not running), trying to create db now"
        cb()


insertDoc = (doc, cb) ->
    post_data = JSON.stringify doc
        
    post_options = {
        host: 'localhost', 
        port: '8000', path: '/'+doc.type, 
        method: 'POST', 
        headers: {
            'Content-Type': 'application/json'
        }
    }  

    post_req = http.request post_options, (res) =>        
        res.setEncoding 'utf8'
        res.on 'data', (chunk) =>
            console.log 'insert ok:', doc
            cb()
 
    post_req.write post_data
    post_req.end()

storageDb = new(cradle.Connection)('http://127.0.0.1', 5984, {cache: true,raw: false}).database('test_storage')
shareDb = new(cradle.Connection)('http://127.0.0.1', 5984, {cache: true,raw: false}).database('test_storage-sharejs')
clearDB storageDb, () =>
    clearDB shareDb, () =>
        app = express()
        
        app.use express.static __dirname
        
        storageServer = new storage.Storage()
                
        storageServer.attachServer app, {'host': 'localhost', 'port': 5984, 'name': 'test_storage'}, (app) ->
            console.log 'inserting from data.json'
            app.listen 8000
            insert = (doc_type, cb) ->
                storageServer.registerDocument doc_type, (error) ->
                    if error?
                        console.log error
                    else
                        doc_array = testData[doc_type]
                        for doc in doc_array
                            insertDoc doc, () ->
                                cb()
            async.eachSeries Object.keys(testData), insert, (error) ->

            storageServer.registerSingleton "TestSingleton"
            

