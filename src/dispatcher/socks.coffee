net = require 'net'
clc = require 'cli-color'
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
        .on 'error', (err) ->
          console.log '\n' + clc.red('serverConnection error: ') + clc.blackBright("#{host}:#{port} on #{localAddress.address}")
          console.log clc.blackBright(err.stack)
          clientConnection.end()
        .on 'end', =>
          @connectionsTotal--
          delete @connectionsByAddress[localAddress.address] if --@connectionsByAddress[localAddress.address] is 0

      clientConnection
        .on 'error', (err) ->
          console.log '\n' + clc.red('clientConnection error: ') + clc.blackBright("#{host}:#{port} on #{localAddress.address}")
          console.log clc.blackBright(err.stack)
          serverConnection.end()

      clientConnection.pipe serverConnection
      serverConnection.pipe clientConnection

    @server.on 'error', (err) ->
      console.log clc.red('server error')
      console.log clc.blackBright(err.stack)

    @server.listen listenPort, listenHost

