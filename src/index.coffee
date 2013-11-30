os = require 'os'
{ inspect } = require 'util'
crypto = require 'crypto'
program = require 'commander'
Logger = require './logger'
Dispatcher = require './dispatcher'
SocksProxy = require './proxy/socks'
HttpProxy = require './proxy/http'

logger = { log, emit, format } = new Logger(tab: 10, gutter: ' ')
  .registerStyle('b', ['bold'])
  .registerStyle('s', ['green']) # Success
  .registerStyle('i', ['cyan']) # Info
  .registerStyle('e', ['red']) # Error
  .registerStyle('a', ['b', 'underline']) # Address

  .registerEvent('request', '<b-i>request')
  .registerEvent('dispatch', '<b-i>dispatch')
  .registerEvent('connect', '<b-s>connect')
  .registerEvent('response', '<b-s>response')
  .registerEvent('error', '<b-e>error')
  .registerEvent('end', '<b-i>end')

  .registerMode('default', ['error'])
  .registerMode('debug', true)

program
  .version('0.0.10')

program
  .command('list')
  .description('list all available network interfaces')
  .action ->
    interfaces = os.networkInterfaces()

    for name, addrs of interfaces
      log "<b>#{name}"

      for { address, family, internal } in addrs
        opts = []
        opts.push family if family
        opts.push 'internal' if internal
        log "    <a>#{address}</>" + if opts.length > 0 then " (#{opts.join ', '})" else ''

      log ''

program
  .command('start')
  .usage('[options] [addresses]')
  .description('start a proxy server')
  .option('-H, --host <h>', 'which host to accept connections from (defaults to localhost)', String)
  .option('-p, --port <p>', 'which port to listen to for connections (defaults to 8080 for HTTP proxy, 1080 for SOCKS proxy)', Number)
  .option('--http', 'start an http proxy server', Boolean)
  .option('--debug', 'log debug info in the console', Boolean)
  .action (args..., { port, host, http, https, debug }) ->
    logger.setMode 'debug' if debug

    addresses = []
    if args.length is 0
      for name, addrs of os.networkInterfaces()
        for addr in addrs when addr.family is 'IPv4' and not addr.internal
          addresses.push address: addr.address, priority: 1
    else
      for arg in args
        [address, priority] = arg.split '@'
        priority = if priority then (parseInt priority) else 1
        addresses.push { address, priority }

    host or= 'localhost'
    dispatcher = new Dispatcher addresses

    if http
      port or= 8080
      type = 'HTTP'
      proxy = new HttpProxy dispatcher, port, host

      proxy
        .on 'request', ({ clientRequest, serverRequest, localAddress }) ->
          id = (crypto.randomBytes 3).toString 'hex'

          emit 'request', "[#{id}] <a>#{clientRequest.url}</>"
          emit 'dispatch', "[#{id}] <a>#{localAddress}</>"

          serverRequest
            .on 'response', (serverResponse) ->
              emit 'response', "[#{id}] <magenta-b>#{serverResponse.statusCode}</>"

            .on 'error', (err) ->
              emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"

            .on 'end', ->
              emit 'end', "[#{id}] serverRequest"

          clientRequest
            .on 'error', (err) ->
              emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"

            .on 'end', ->
              emit 'end', "[#{id}] clientRequest"

        .on 'error', (err) ->
          emit 'error', "server\n#{escape err.stack}"

    else
      port or= 1080
      type = 'SOCKS5'
      proxy = new SocksProxy dispatcher, port, host

      proxy
        .on 'request', ({ serverConnection, clientConnection, host, port, localAddress }) ->
          id = (crypto.randomBytes 3).toString 'hex'

          emit 'request', "[#{id}] <a>#{host}</><b>:#{port}</>"
          emit 'dispatch', "[#{id}] <a>#{localAddress}</>"

          serverConnection
            .on 'connect', ->
              emit 'connect', "[#{id}] <a>#{host}</><b>:#{port}</>"

            .on 'error', (err) ->
              emit 'error', "[#{id}] serverConnection\n#{escape err.stack}"

            .on 'end', ->
              emit 'end', "[#{id}] serverConnection"

          clientConnection
            .on 'error', (err) ->
              emit 'error', "[#{id}] clientConnection\n#{escape err.stack}"

            .on 'end', ->
              emit 'end', "[#{id}] clientConnection"

        .on 'error', (err) ->
          emit 'error', "server\n#{escape err.stack}"

        .on 'clientError', (err, data) ->
          emit 'error', "client\n#{escape err.message}\n<b>Received:</>\n#{escape (inspect data)}\n#{escape data.toString()}"

    log """
      <bold-magenta>#{type}</> server started on <a>#{host}</><b>:#{port}</>
      Dispatching to addresses #{("<a>#{address}</><b>@#{priority}</>" for { address, priority } in addresses).join ', '}
    """

program.parse process.argv
