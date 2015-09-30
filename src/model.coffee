_setInterval = require('setinterval-plus')
time = require('english-time')

module.exports = {
  name: "recurry"
  host: "localhost:4040"
  resources:
    "/scheduler/remove/:id":
      get:
        description: "stops and removes a scheduler"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot remove nonexisting id" } if not scheduler 
          lib.removeScheduler(scheduler)
          res.send {ok:true}
          next()
          
    "/scheduler/trigger/:id":
      put:
        description: "manually triggers a scheduler id"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot update nonexisting id" } if not scheduler 
          lib.execute scheduler 
          scheduler.status = "triggered"
          lib.updateCache()
          res.send {ok:true}
          next()

    "/scheduler/action/:id":
      put:
        description: "starts/stops/pauses/resumes a scheduler"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot update nonexisting id" } if not scheduler 
          scheduler.timer[req.body.action]() if scheduler.timer
          scheduler.status = req.body.action+"'d"
          lib.updateCache()
          res.send {ok:true}
          next()
        required: ["action"]  
        payload:
          action:
            id: "http://recurry/scheduler/action"
            type: "string"
            default: "pause"
            enum: ["start","stop","pause","resume","trigger"] 
        
    "/scheduler/rule/:id":
      put:
        description: "sets the scheduler"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot update nonexisting id" } if not scheduler 
          scheduler.scheduler = req.body.scheduler 
          freq = time( scheduler.scheduler )
          if freq < 3000 or freq is undefined
            scheduler.scheduler = "?"
            res.send {error: "invalid frequency or smaller than 3 seconds" }
            return lib.updateScheduler(s)
          if scheduler.timer?
            scheduler.timer.stop() if typeof scheduler.timer.stop is 'function'
            delete scheduler.timer
          lib.startScheduler(scheduler,freq)
          lib.updateScheduler(scheduler) 
          res.send {ok:true} 
          next()
        required: ["scheduler"]
        payload:
          scheduler:
            id: "http://recurry/scheduler"
            type: "string"
            default: "5 minutes"
    "/scheduler":
      get:
        description: "returns complete content of scheduled jobs"
        function: (req,res,next,lib) ->
          res.send lib.cache.scheduler 
          next()
      post:
        description: "allows posting of a job scheduler every x hours/minutes/days"
        required: ["method","url"]
        payload:
          method: 
            id: "http://recurry/method"
            type: "string"
            enum: ["get","post","put","delete","options"]
            default: "post"
          id: 
            id: "http://recurry/id"
            type: "string"
            default: "call foo"
          url: 
            id: "http://recurry/url"
            type: "string"
            default: "http://foo.com/ping"
          payload:
            id: "http://recurry/payload"
            type: "object"
          scheduler:
            id: "http://recurry/scheduler"
            type: "string"
            default: "5 minutes"
        function: (req,res,next,lib) ->
          lib.cache.scheduler.push {
            id: req.body.id || (lib.cache.scheduler.length+1)
            method: req.body.method || "post"
            url: req.body.url
            payload: req.body.payload || {}
            scheduler: req.body.scheduler || "?"
            triggered: 0
            triggered_last:""
          }
          lib.updateCache()
          res.send req.params
    "/scheduler/:id":
      get:
        description: "get a scheduler object including payload "
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot get nonexisting id" } if not scheduler 
          res.send scheduler 
          next()
    "/scheduler/reset/:id":
      get:
        description: "resets the 'triggered' counter of a scheduled job"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot get nonexisting id" } if not scheduler 
          scheduler.triggered = 0
          lib.updateScheduler(scheduler)
          res.send req.params
          next()
    "/scheduler/payload/:id":
      put:
        description: "updates (optional) specific arguments which will be passed to the job"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot get nonexisting id" } if not scheduler 
          scheduler.payload = JSON.parse(req.body.payload)
          lib.updateScheduler(scheduler)
          res.send req.params
          next()

  doc:
    version: 1
    projectname: "Recurry"
    logo: "http://www.unileverfoodsolutions.com.au/wu_cache/img/069/mis_50090518/Mild_Chicken_Curry_0000x0000_0.jpg" 
    host: "http://lb.recurry.cloud.2webapp.com"
    homepage: "http://lb.recurry.cloud.2webapp.com/v1/doc/html"
    security: ""
    description: "A recurrent REST call scheduler.<br>You can think of recurry as cron+flock on a unix platform, except without the files (but a REST interface).<br>These days almost anything can be triggered using REST calls, so meet Recurry.<br>Recurry does recurring REST calls, with a nice degree of (remote) control."
    request: 
      curl: "curl -X {{method}} -H 'Content-Type: application/json' -H 'X-FOO-TOKEN: YOURTOKEN' '{{url}}' --data '{{payload}}' "
      jquery: "jQuery.ajax({ url: '{{url}}', method: {{method}}, data: {{payload}} }).done(function(res){ alert(res); });"
      php: "$client->{{method}}('{{url}}', '{{payload}}');"
      coffeescript: "request.{{method}}\n\theaders: {'X-FOO-TOKEN': apikey }\n\turl: '{{url}}'\n\tjson: true\n\tbody: {{payload}}\n,(error,reponse,body) ->\n\tok = !error and response.statusCode == 200 and response.body"
      nodejs: "request.post({\n\theaders: {\n\t\t'X-FOO-TOKEN': apikey\n\t},\n\turl: '{{url}}',\n\tjson:true,\n\tbody: {{payload}}\n}, function(error, reponse, body) {\n\tvar ok;\n\treturn ok = !error && response.statusCode === 200 && response.body;\n});"
      php: "$json = '{{payload}}';\n$ch = curl_init( '{{url}}' );\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper('{{method}}') );\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $json);\ncurl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, true);\ncurl_setopt($ch, CURLOPT_HTTPHEADER, array(\n\t'Content-Type: application/json',\n\t'Content-Length: ' . strlen($json))\n);\n$result = curl_exec($ch);\n// HINT: use a REST client like https://github.com/bproctor/rest\n//       or install one using composer: http://getcomposer.org"
      python: "import requests, json\nurl = '{{url}}'\ndata = json.dumps( {{payload}} )\nr = requests.post( url, data, auth=('user', '*****'))\nprint r.json"

  replyschema:
    type: 'object'
    required: ['code','message','kind','data']
    messages:
      0: 'feeling groovy'
      1: 'unknown error'
      2: 'your payload is invalid (is object? content-type is application/json?)'
      3: 'data error'
      4: 'access denied'
    payload:
      code:       { type: 'integer', default: 0 }
      message:    { type: 'string',  default: 'feeling groovy' }
      kind:       { type: 'string',  default: 'default', enum: ['book','default'] }
      data:       { type: 'object',  default: {} }
      errors:     { type: 'object',  default: [] }
}
