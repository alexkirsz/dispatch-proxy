net = require 'net'
{ EventEmitter } = require 'events'
socks = require '../socks'
{ STATUS } = require '../socks/const'

module.exports = class SocksProxy extends EventEmitter
  constructor: (dispatcher, listenPort, listenHost) ->
    super

    @server = socks.createServer (clientConnection, host, port, callback) =>
      localAddress = dispatcher.dispatch()

      serverConnection = net.createConnection { host, port, localAddress }

      _responded = false
      serverConnection
        .on 'connect', =>
          _responded = true
          callback STATUS.SUCCESS

        .on 'error', (err) =>
          if not _responded
            _responded = true
            switch err.code
              # Host unreachable
              when 'EHOSTUNREACH' then callback STATUS.HOST_UNREACHABLE
              # Connection refused
              when 'ECONNREFUSED' then callback STATUS.CONNECTION_REFUSED
              # Network unreachabke
              when 'ENETUNREACH' then callback STATUS.NETWORK_UNREACHABLE
              else callback STATUS.SERVER_FAILURE

        .on 'end', =>
          dispatcher.free localAddress

      clientConnection.pipe serverConnection
      serverConnection.pipe clientConnection

      @emit 'request', { serverConnection, clientConnection, host, port, localAddress }

    @server.on 'error', (err) => @emit 'error', err
    @server.on 'clientError', (err, data) => @emit 'clientError', err, data

    @server.listen listenPort, listenHost

