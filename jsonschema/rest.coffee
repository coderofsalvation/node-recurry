_setInterval = require('setinterval-plus')
time = require('english-time')

module.exports = {
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
        payload:
          type: "object",
          properties: 
            action:
              id: "http://recurry/scheduler/action"
              type: "string"
              required: true
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
        payload:
          type: "object",
          properties: 
            scheduler:
              id: "http://recurry/scheduler"
              type: "string"
              required: true
              default: "5 minutes"
    "/scheduler":
      get:
        description: "returns complete content of scheduled jobs"
        function: (req,res,next,lib) ->
          res.send lib.cache.scheduler 
          next()
      post:
        description: "allows posting of a job scheduler"
        payload:
          type: "object",
          properties: 
            method: 
              id: "http://recurry/method"
              type: "string"
              required: true
              enum: ["get","post","put","delete","options"]
              default: "post"
            id: 
              id: "http://recurry/id"
              type: "string"
              default: "call foo"
            url: 
              id: "http://recurry/url"
              type: "string"
              required: true
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
    "/payload/:id":
      put:
        description: "updates (optional) specific arguments which will be passed to the job"
        function: (req,res,next,lib) ->
          scheduler = lib.getScheduler(req.params.id) 
          return res.send {code:3, msg: "cannot get nonexisting id" } if not scheduler 
          scheduler.payload = JSON.parse(req.body.payload)
          lib.updateScheduler(scheduler)
          res.send req.params
          next()
}
