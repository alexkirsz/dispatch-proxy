net = require 'net'
colog = require 'colog'
socks = require '../socks'
Dispatcher = require './'

module.exports = class SocksDispatcher extends Dispatcher
  constructor: (@addresses, listenPort, listenHost) ->
    super

    @server = socks.createServer (clientConnection, { host, port }) =>
      localAddress = @dispatchAddress()

      serverConnection = net.createConnection
        port: port
        host: host
        localAddress: localAddress.address

      @emit 'connection', { client: clientConnection, server: serverConnection, localAddress, host, port }

      serverConnection
        .on 'connect', =>
          @connectionsByAddress[localAddress.address] or= 0
          @connectionsByAddress[localAddress.address]++
          @connectionsTotal++
        .on 'end', =>
          @connectionsTotal--
          delete @connectionsByAddress[localAddress.address] if --@connectionsByAddress[localAddress.address] is 0

      clientConnection.pipe serverConnection
      serverConnection.pipe clientConnection

    @server.on 'error', (err) =>
      @emit 'error', err

    @server.listen listenPort, listenHost

