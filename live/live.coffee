root = exports ? window

objectToHtml = (obj) ->
    json = JSON.stringify obj, undefined, 4
    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    html = json.replace /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, (match) ->
            cls = 'number'
            if (/^"/.test(match)) 
                if (/:$/.test(match)) 
                    cls = 'key'
                else 
                    cls = 'string'
            else if (/true|false/.test(match))
                cls = 'boolean'
            else if (/null/.test(match))
                cls = 'null'
            return '<span class="' + cls + '">' + match + '</span>'
    return html
    

displayDoc = () ->
    toDisplay = doc._doc
    toDisplay.body = body.snapshot
    $('#json').empty() 
    $('#json').append objectToHtml toDisplay

displaySingleton = () ->
    $('#json').empty() 
    $('#json').append objectToHtml root.body.snapshot

loadLiveView = () ->
    path = window.location.pathname.split '/'
    if path.length == 3
        doctype = path[1]
        docid = path[2]
    
        storage.getDocument doctype, docid, (error, doc) ->
            root.doc = doc
            doc.getBody (error, body) ->
                if error?
                    console.log error
                else
                    root.body = body
                    body.on 'remoteop', (op) ->
                        displayDoc()
                    displayDoc()
    else if path.length == 2
        storage.getSingleton path[1], (error, doc) ->
            if error?
                throw error
            else
                root.body = doc
                doc.on 'remoteop', (op) ->
                    displaySingleton()
                displaySingleton()

$(document).ready () ->
    storage.initializeCache '../', () ->
        loadLiveView()