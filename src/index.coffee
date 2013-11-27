os = require 'os'
{ print } = require 'util'
crypto = require 'crypto'
program = require 'commander'
colog = require 'colog'
SocksDispatcher = require './dispatcher/socks'
HttpDispatcher = require './dispatcher/http'

program
  .version('0.0.1')

program
  .command('list')
  .description('list all available network interfaces')
  .action ->
    interfaces = os.networkInterfaces()

    for name, addrs of interfaces
      print (colog.green name) + '\n'

      for { address, family, internal } in addrs
        print '  ' + (colog.cyan address)
        opts = []
        opts.push family if family
        opts.push 'internal' if internal
        print " (#{opts.join ', '})" if opts.length > 0
        print '\n'

      print '\n'

program
  .command('start')
  .usage('[options] [addresses]')
  .description('start a proxy server')
  .option('-H, --host <h>', 'which host to accept connections from (defaults to localhost)', String)
  .option('-p, --port <p>', 'which port to listen to for connections (defaults to 8080 for HTTP proxy, 1080 for SOCKS proxy)', Number)
  .option('--http', 'start an http proxy server', Boolean)
  .option('--debug', 'logs connections and errors', Boolean)
  .action (args..., { port, host, http, https, debug }) ->
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
      dispatcher = new HttpDispatcher addresses, port, host
    else
      port or= 1080
      type = 'SOCKS5'
      dispatcher = new SocksDispatcher addresses, port, host

      if debug
        dispatcher
          .on 'connection', ({ client, server, host, port, localAddress }) ->
            id = (crypto.randomBytes 3).toString 'hex'

            console.log """
              #{colog.yellow id} - Received connection to #{colog.cyan "#{host}:#{port}"}, dispatching to #{colog.cyan "#{localAddress.address}@#{localAddress.priority}"}.
            """

            server
              .on 'connect', ->
                console.log """
                  #{colog.green id} - Successfully connected to #{colog.cyan "#{host}:#{port}"} (#{colog.cyan "#{server.remoteAddress}:#{server.remotePort}"}) from #{colog.cyan "#{server.localAddress}:#{server.localPort}"}.
                """

              .on 'error', (err) ->
                console.log """
                  #{colog.red id} - serverConnection error
                  #{'         ' + (err.stack.replace /\n/g, '\n         ')}
                """

              .on 'end', ->
                console.log """
                  #{colog.yellow id} - serverConnection ended
                """

            client
              .on 'error', (err) ->
                console.log """
                  #{colog.red id} - clientConnection error
                  #{'         ' + (err.stack.replace /\n/g, '\n         ')}
                """

              .on 'end', ->
                console.log """
                  #{colog.yellow id} - clientConnection ended
                """

          .on 'error', (err) ->
            console.log """
              #{colog.red "server error"}
              #{err.stack}
            """

    console.log """
      #{type} server started on #{colog.green "#{host}:#{port}"}
      Dispatching to addresses #{(colog.cyan "#{address}@#{priority}" for { address, priority } in addresses).join ', '}
    """

program.parse process.argv
