os = require 'os'
{ print } = require 'util'
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
  .option('-p, --port <p>', 'which port to listen to for connections (defaults to 55667)', Number)
  .option('--http', 'start an http proxy server', Boolean)
  .action (args..., { port, host, http, https }) ->
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

    port or= 55667
    host or= 'localhost'

    if http
      type = 'HTTP'
      dispatcher = new HttpDispatcher addresses, port, host
    else
      type = 'SOCKS5'
      dispatcher = new SocksDispatcher addresses, port, host

    print "#{type} server started on " + (colog.green "#{host}:#{port}") + '\n'
    print 'Dispatching to addresses '
    print (colog.cyan "#{address}@#{priority}" for { address, priority } in addresses).join ', '
    print '\n'

    dispatcher.on 'error', ({ type, host, port, localAddress }, err) ->
      if type is 'server'
        print (colog.red "#{type} error")
      else
        print (colog.red "#{type} error: ") + "#{host}:#{port} on #{localAddress.address}"

program.parse process.argv
