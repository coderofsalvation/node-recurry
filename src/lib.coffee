flat = require('flat-file-cache')
time = require('english-time')
request = require('request')
_setInterval = require('setinterval-plus')

Cache = (file) ->
  @file = file
  @cache = require(file)
  @set = (key,value) =>
    @cache[key] = value
    require('fs').fileWriteSync( file, JSON.stringify(@cache,null,2) )

  @get = (key,cb) =>
    cb(@cache[key]) if cb
    return @cache[key] 

  return @

obj = {}

obj.cacheFile = new Cache( process.env.RECURRY_CACHEFILE || process.cwd()+'/cache.json' )

obj.updateCache = () ->
  this.cacheFile.set "cache", this.cache

obj.init = (cb) ->
  me = this
  this.cacheFile.get 'cache', (result) ->
    me.cache = result || {"scheduler":[],"timers":[]}
    me.startSchedulers(me.cache)
    cb(me)

obj.getScheduler = (id) ->
  for obj in this.cache.scheduler
    return obj if parseInt(obj.id) == parseInt(id) or obj.id == id
  return false

obj.updateScheduler = (scheduler) ->
  for k,obj of this.cache.scheduler
    this.cache.scheduler[k] = scheduler if parseInt(obj.id) == parseInt(scheduler.id)
  this.updateCache()

obj.startSchedulers = (cache) ->
  if cache? and cache.scheduler?
    for s in cache.scheduler
      continue if s.scheduler == "?" or (s.status? and s.status.match(/stop/))
      freq = time( s.scheduler )
      if freq < 5000 or freq is undefined
        s.scheduler = "?"
        this.updateScheduler(s)
        continue
      ((s,freq,lib) ->
        console.dir s.id+": "+s.scheduler
        lib.startScheduler(s,freq)
      )(s,freq,this) 

obj.startScheduler = (scheduler,freq) ->
  lib = this
  scheduler.timer = new _setInterval () ->
    scheduler.triggered++ 
    scheduler.triggered_last = new Date()
    scheduler.status = "start'd"
    lib.execute(scheduler)
  , freq, scheduler, lib
  this.updateScheduler(scheduler)
          
obj.removeScheduler = (scheduler) ->
  schedulers = []
  if scheduler.timer?
    scheduler.timer.stop() if typeof scheduler.timer.stop is 'function'
    delete scheduler.timer
  for s in this.cache.scheduler
    schedulers.push s if s.id != scheduler.id
  this.cache.scheduler = schedulers
  this.updateCache()

obj.execute = (scheduler) ->
  data =  {
    method: scheduler.method
    url: scheduler.url 
  }
  console.log new Date()+" every "+scheduler.scheduler+": "+scheduler.method+" "+scheduler.url
  data.json = scheduler.payload if scheduler.payload and scheduler.method != "get"
  console.dir data 
  request data, (err,res,body) ->
    console.dir body 
    console.error err if err

module.exports = obj
