os = require 'os'
{ inspect } = require 'util'
crypto = require 'crypto'
program = require 'commander'
Logger = require 'tmpl-log'
SocksProxy = require './proxy/socks'
HttpProxy = require './proxy/http'

logger = new Logger(tab: 10, gutter: ' ')
  .registerTag('b', ['bold'])
  .registerTag('s', ['green']) # Success
  .registerTag('i', ['cyan']) # Info
  .registerTag('e', ['red']) # Error
  .registerTag('a', ['b', 'underline']) # Address

  .registerEvent('request', '<b><i>request')
  .registerEvent('dispatch', '<b><i>dispatch')
  .registerEvent('connect', '<b><s>connect')
  .registerEvent('response', '<b><s>response')
  .registerEvent('error', '<b><e>error')
  .registerEvent('end', '<b><i>end')

  .registerMode('default', ['error'])
  .registerMode('debug', true)

program
  .version('0.1.2')

program
  .command('list')
  .description('list all available network interfaces')
  .action ->
    interfaces = os.networkInterfaces()

    for name, addrs of interfaces
      logger.log "<b>#{name}"

      for { address, family, internal } in addrs
        opts = []
        opts.push family if family
        opts.push 'internal' if internal
        logger.log "    <a>#{address}</>" + if opts.length > 0 then " (#{opts.join ', '})" else ''

      logger.log ''

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

    if http
      port or= 8080
      type = 'HTTP'
      proxy = new HttpProxy addresses, port, host

      proxy
        .on 'request', ({ clientRequest, serverRequest, localAddress }) ->
          id = (crypto.randomBytes 3).toString 'hex'

          logger.emit 'request', "[#{id}] <a>#{clientRequest.url}</>"
          logger.emit 'dispatch', "[#{id}] <a>#{localAddress}</>"

          serverRequest
            .on 'response', (serverResponse) ->
              logger.emit 'response', "[#{id}] <magenta><b>#{serverResponse.statusCode}</></>"

            .on 'error', (err) ->
              logger.emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"

            .on 'end', ->
              logger.emit 'end', "[#{id}] serverRequest"

          clientRequest
            .on 'error', (err) ->
              logger.emit 'error', "[#{id}] clientRequest\n#{escape err.stack}"

            .on 'end', ->
              logger.emit 'end', "[#{id}] clientRequest"

        .on 'error', (err) ->
          logger.emit 'error', "server\n#{escape err.stack}"

    else
      port or= 1080
      type = 'SOCKS'
      proxy = new SocksProxy addresses, port, host

      proxy
        .on 'request', ({ serverConnection, clientConnection, host, port, localAddress }) ->
          id = (crypto.randomBytes 3).toString 'hex'

          logger.emit 'request', "[#{id}] <a>#{host}</><b>:#{port}</>"
          logger.emit 'dispatch', "[#{id}] <a>#{localAddress}</>"

          serverConnection
            .on 'connect', ->
              logger.emit 'connect', "[#{id}] <a>#{host}</><b>:#{port}</>"

            .on 'error', (err) ->
              logger.emit 'error', "[#{id}] serverConnection\n#{escape err.stack}"

            .on 'end', ->
              logger.emit 'end', "[#{id}] serverConnection"

          clientConnection
            .on 'error', (err) ->
              logger.emit 'error', "[#{id}] clientConnection\n#{escape err.stack}"

            .on 'end', ->
              logger.emit 'end', "[#{id}] clientConnection"

        .on 'error', (err) ->
          logger.emit 'error', "server\n#{escape err.stack}"

        .on 'socksError', (err) ->
          logger.emit 'error', "socks\n#{escape err.message}"

    logger.log """
      <b><magenta>#{type}</></> server started on <a>#{host}</><b>:#{port}</>
      Dispatching to addresses #{("<a>#{address}</><b>@#{priority}</>" for { address, priority } in addresses).join ', '}
    """

program.parse process.argv
