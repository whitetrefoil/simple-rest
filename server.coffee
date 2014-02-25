_ = require 'underscore'
util = require 'util'
restify = require 'restify'
data = require './data/bootstrap_data'

server = restify.createServer()
server.use(restify.acceptParser(server.acceptable))
server.use(restify.bodyParser({ mapParams: false }))

# Common Methods
clone = (obj) -> JSON.parse(JSON.stringify(obj))
get = (collection, id, res, next) ->
  id = parseInt(id, 10)
  model = _.findWhere data[collection], { id: id }
  if model?
    res.send model
    next()
  else
    next new restify.ResourceNotFoundError()

post = (collection, body, res, next) ->
  id = _.max(data[collection], (d) -> d.id).id + 1
  model = clone(body)
  model.id = id
  data[collection].push model
  res.send 201, model
  next()

put = (collection, id, body, res, next) ->
  id = parseInt(id, 10)
  model = _.findWhere data[collection], { id: id }
  if model?
    body = clone(body)
    body.id = id
    _.extend model, body
    res.send body
    next()
  else
    next(new restify.ResourceNotFoundError())

del = (collection, id, res, next) ->
  id = parseInt(id, 10)
  index = null
  data[collection].some (m, i) ->
    if m.id is id
      index = i
  if index?
    model = data[collection].splice(index, 1)[0]
    res.send model
    next()
  else
    next(new restify.ResourceNotFoundError())


# Test
server.get '/test', (req, res, next) ->
  res.send
    content: 'test'
  next()


# Routers
resource = (name, ser) ->
  root = "/#{name}"
  rootWithId = "#{root}/:id"

  ser.get root, (req, res, next) ->
    res.send data[name]
    next()

  ser.get rootWithId, (req, res, next) ->
    get name, req.params.id, res, next

  ser.post root, (req, res, next) ->
    post name, req.body, res, next

  ser.put rootWithId, (req, res, next) ->
    put name, req.params.id, req.body, res, next

  ser.del rootWithId, (req, res, next) ->
    del name, req.params.id, res, next

['boards', 'posts', 'replies'].forEach (res) ->
  resource(res, server)


# Start Server
server.listen 8888, -> console.log "#{server.name} listening at #{server.url}"
