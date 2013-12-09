net = require 'net'
socks = require 'socks-handler'
Dispatcher = require '../dispatcher'

module.exports = class SocksProxy extends Dispatcher
  constructor: (addresses, listenPort, listenHost) ->
    super addresses

    @server = net.createServer (clientConnection) =>
      socks.handle clientConnection, (err, handler) =>
        if err
          @emit 'socksError', err
          return

        handler.on 'error', (err) ->
          @emit 'socksError', err

        handler.on 'request', ({ version, command, host, port }, callback) =>
          if command isnt socks[5].COMMAND.CONNECT
            @emit 'socksError', new Error "Unsupported command: #{command}"
            if version is 5
              callback socks[5].REQUEST_STATUS.COMMAND_NOT_SUPPORTED
            else
              callback socks[4].REQUEST_STATUS.REFUSED
            return

          localAddress = @dispatch()
          serverConnection = net.createConnection { port, host, localAddress }

          clientConnection.pipe(serverConnection).pipe(clientConnection)

          serverConnection
            .on 'error', onConnectError = (err) ->
              if version is 5
                status =
                  switch err.code
                    when 'EHOSTUNREACH' then socks[5].REQUEST_STATUS.HOST_UNREACHABLE
                    when 'ECONNREFUSED' then socks[5].REQUEST_STATUS.CONNECTION_REFUSED
                    when 'ENETUNREACH' then socks[5].REQUEST_STATUS.NETWORK_UNREACHABLE
                    else socks[5].REQUEST_STATUS.SERVER_FAILURE
              else
                status = socks[4].REQUEST_STATUS.FAILED

              callback status

            .on 'connect', ->
              serverConnection.removeListener 'error', onConnectError
              status = if version is 5 then socks[5].REQUEST_STATUS.SUCCESS else socks[4].REQUEST_STATUS.GRANTED
              callback status

            .on 'end', =>
              @free localAddress

          @emit 'request', { clientConnection, serverConnection, host, port, localAddress }

    @server.on 'error', (err) => @emit 'error', err

    @server.listen listenPort, listenHost

