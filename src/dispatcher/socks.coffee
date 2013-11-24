net = require 'net'
colog = require 'colog'
socks = require '../socks'
Dispatcher = require './'

module.exports = class SocksDispatcher extends Dispatcher
  constructor: (@addresses, listenPort, listenHost) ->
    super

    @server = socks.createServer (clientConnection, { host, port }) =>
      localAddress = @dispatchAddress()
      @connectionsByAddress[localAddress.address] or= 0
      @connectionsByAddress[localAddress.address]++
      @connectionsTotal++

      serverConnection = net.createConnection
        port: port
        host: host
        localAddress: localAddress.address

      serverConnection
        .on 'error', (err) =>
          clientConnection.end()
          @emit 'error', { type: 'serverConnection', host, port, localAddress }, err
        .on 'end', =>
          @connectionsTotal--
          delete @connectionsByAddress[localAddress.address] if --@connectionsByAddress[localAddress.address] is 0

      clientConnection
        .on 'error', (err) ->
          serverConnection.end()
          @emit 'error', { type: 'clientConnection', host, port, localAddress }, err

      clientConnection.pipe serverConnection
      serverConnection.pipe clientConnection

    @server.on 'error', (err) =>
      @emit 'error', type: 'server', err

    @server.listen listenPort, listenHost

