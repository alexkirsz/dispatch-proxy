http = require 'http'
url = require 'url'
Dispatcher = require '../dispatcher'

module.exports = class HttpProxy extends Dispatcher
  constructor: (addresses, listenPort, listenHost) ->
    super addresses

    agent = new http.Agent maxSockets: Infinity

    @server = http.createServer (clientRequest, clientResponse) =>
      localAddress = @dispatch()

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
        .on 'end', =>
          @free localAddress

      @emit 'request', { clientRequest, serverRequest, localAddress }

    @server.listen listenPort, listenHost
