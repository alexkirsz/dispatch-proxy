http = require 'http'
url = require 'url'
{ EventEmitter } = require 'events'

module.exports = class HttpProxy extends EventEmitter
  constructor: (dispatcher, listenPort, listenHost) ->
    super

    agent = new http.Agent maxSockets: Infinity

    @server = http.createServer (clientRequest, clientResponse) =>
      localAddress = dispatcher.dispatch()

      options = url.parse clientRequest.url
      options.localAddress = localAddress
      options.method = clientRequest.method
      options.headers = clientRequest.headers
      options.agent = agent

      serverRequest = http.request options

      clientRequest.pipe serverRequest

      serverRequest
        .on 'response', (serverResponse) ->
          clientResponse.writeHead serverResponse.statusCode, serverResponse.headers
          serverResponse.pipe clientResponse
        .on 'error', (error) ->
          clientResponse.writeHead 502 # Bad gateway
          clientResponse.end()

      serverRequest.on 'end', ->
        dispatcher.free localAddress

      @emit 'request', { clientRequest, serverRequest, localAddress }

    @server.listen listenPort, listenHost
