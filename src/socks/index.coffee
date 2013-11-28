Server = require './server'

module.exports =
  createServer: (callback) ->
    server = new Server
    server.on 'request', callback
    return server

  Server: Server
