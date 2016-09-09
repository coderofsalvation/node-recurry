# Recurry 

recurrent REST call scheduler 

> Note: for delayed jobs please use a queue like kue 

These days almost anything can be triggered using REST calls, so meet Recurry.
Recurry does recurring REST calls, with a nice degree of (remote) control.

You can think of recurry as cron+flock on a unix platform, except without the files (but a REST interface).

# Usage 

    $ npm install recurry coffee-script
    $ echo '{"scheduler":[],"timers":[]}' > cache.json
    $ RECURRY_CACHEFILE="cache.json" ./server

> NOTE: Recurry supports persistance, but does not require a database (instead it uses a local jsonfile)

# Hubot interface 

Instead of fiddling with crontab-files, the `recurry-hubot` module allows hubot interfacing with the REST api: 

* starting, stopping, pausing, resuming recurring REST calls
* adding and removing REST calls including payload

Make sure you run `npm install recurry-hubot` in your hubot rootdir, and get in control:

    hubot> recurry

    id           method  url                          payload  scheduler  triggered  triggered_last            status   timer
    -----------  ------  ---------------------------  -------  ---------  ---------  ------------------------  -------  -----
    ping         post    http://foo.com/ping          {}       1 minutes  1235       2015-06-12T13:35:49.173Z  start'd  {}   
    pushjob      post    http://queue.foo.com/ping    {}       5 minutes  54         2015-06-12T13:35:49.173Z  start'd  {}   
    flapjob      post    http://queue.foo.com/flap    {}       5 minutes  54         2015-06-12T13:35:49.173Z  start'd  {}   
    ...

# JSON API

Documentation of API endpoints

### GET /scheduler/remove/:id

stops and removes a scheduler

### PUT /scheduler/trigger/:id

manually triggers a scheduler id

### PUT /scheduler/action/:id

starts/stops/pauses/resumes a scheduler

Example payload:

     {
       "action": "pause"
     }

JSON Schema:

     {
       "type": "object",
       "properties": {
         "action": {
           "id": "http://recurry/scheduler/action",
           "type": "string",
           "required": true,
           "default": "pause",
           "enum": [
             "start",
             "stop",
             "pause",
             "resume",
             "trigger"
           ]
         }
       }
     }

### PUT /scheduler/rule/:id

sets the scheduler

Example payload:

     {
       "scheduler": "5 minutes"
     }

JSON Schema:

     {
       "type": "object",
       "properties": {
         "scheduler": {
           "id": "http://recurry/scheduler",
           "type": "string",
           "required": true,
           "default": "5 minutes"
         }
       }
     }

### GET /scheduler

returns complete content of scheduled jobs

### POST /scheduler

allows posting of a job scheduler

Example payload:

     {
       "method": "post",
       "id": "call foo",
       "url": "http://foo.com/ping",
       "payload": {},
       "scheduler": "5 minutes"
     }

JSON Schema:

     {
       "type": "object",
       "properties": {
         "method": {
           "id": "http://recurry/method",
           "type": "string",
           "required": true,
           "enum": [
             "get",
             "post",
             "put",
             "delete",
             "options"
           ],
           "default": "post"
         },
         "id": {
           "id": "http://recurry/id",
           "type": "string",
           "default": "call foo"
         },
         "url": {
           "id": "http://recurry/url",
           "type": "string",
           "required": true,
           "default": "http://foo.com/ping"
         },
         "payload": {
           "id": "http://recurry/payload",
           "type": "object"
         },
         "scheduler": {
           "id": "http://recurry/scheduler",
           "type": "string",
           "default": "5 minutes"
         }
       }
     }

### GET /scheduler/:id

get a scheduler object including payload 

### GET /scheduler/reset/:id

resets the 'triggered' counter of a scheduled job

### PUT /payload/:id

updates (optional) specific arguments which will be passed to the job

