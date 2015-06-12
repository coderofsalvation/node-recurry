restify = require('restify')
JSV = require('JSV').JSV.createEnvironment()
defaults = require('json-schema-defaults')
schema = require('./../jsonschema/rest.coffee')

obj = {}

obj.getServer = (lib) ->
  server = restify.createServer(
    name: 'recurry'
    version: '1.0.0'
    formatters:
      'application/json': this.format
  )
  server.use restify.acceptParser(server.acceptable)
  server.use restify.queryParser()
  server.use restify.bodyParser()

  this.init server, lib, schema
  return server

obj.format = (req, res, body) ->
  # Copied from restify/lib/formatters/json.js
  if body instanceof Error
    # snoop for RestError or HttpError, but don't rely on
    # instanceof
    res.statusCode = body.statusCode or 500
    if body.body
      body =
        code: 1
        scode: body.body.code
        msg: body.body.message
    else
      body =
        code: 1
        msg: body.message
  else if Buffer.isBuffer(body)
    body = body.toString('base64')
  data = JSON.stringify(body)
  res.setHeader 'Content-Length', Buffer.byteLength(data)
  data

obj.init = (server, lib) ->
  for url,methods of schema.resources
    for method,resource of methods
      console.log "registering REST resource: "+url+" ("+method+")"
      server[method] url, ( (resource) ->
        (req,res,next) ->
          err = JSV.validate( req.body, resource.payload )
          if err.errors.length == 0
            resource.function(req,res,next,lib)
          else
            res.send {code:2, error: err.errors } 
      )(resource) 

  server.get "/doc", (req,res,next) ->
    indent = (spaces,str) ->
      return str if str == undefined
      lines = str.split("\n");
      blank = ""
      blank = blank + " " for i in [0..spaces]
      ( lines[k] = blank + line for k,line of lines )
      return lines.join("\n");

    line        = "\n\n"
    header      = "JSON API\n========"+line
    description = process.env.API_DESC || "Documentation of API endpoints"+line
    restext     = ""
    for url,methods of schema.resources
      for method,resource of methods
        restext += "### "+method.toUpperCase()+" "+url+line
        restext += (if resource.description? then resource.description+line else "no description (yet)"+line)
        continue if not resource.payload? or not method?
        restext += "Example payload:"+line+indent( 4, JSON.stringify(defaults(resource.payload),null,2) )+line
        restext += "JSON Schema:"+line+indent( 4, JSON.stringify(resource.payload,null,2) )+line
    body = header+description+restext
    res.writeHead 200, 
      'Content-Length': Buffer.byteLength(body),
      'Content-Type': 'text/plain'
    res.write(body)
    res.end()

module.exports = obj
