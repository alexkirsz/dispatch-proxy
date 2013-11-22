http = require 'http'
url = require 'url'
Dispatcher = require './'

module.exports = class HttpDispatcher extends Dispatcher
  constructor: (@addresses, port, host) ->
    super

    agent = new http.Agent maxSockets: Infinity

    @server = http.createServer (clientRequest, clientResponse) =>
      localAddress = @dispatchAddress()
      @connectionsByAddress[localAddress.address] or= 0
      @connectionsByAddress[localAddress.address]++
      @connectionsTotal++

      options = url.parse clientRequest.url
      options.localAddress = localAddress.address
      options.method = clientRequest.method
      options.headers = clientRequest.headers
      options.agent = agent

      serverRequest = @createRequest options

      clientRequest.pipe serverRequest

      serverRequest
        .on 'response', (serverResponse) ->
          clientResponse.writeHead serverResponse.statusCode, serverResponse.headers
          serverResponse.pipe clientResponse
        .on 'error', (error) ->
          serverRequest.removeAllListeners()
          clientResponse.destroy()

      clientResponse.on 'end', =>
        @connectionsTotal--
        delete @connectionsByAddress[localAddress.address] if --@connectionsByAddress[localAddress.address] is 0

    @server.listen port, host

  createRequest: (options) ->
    http.request options
