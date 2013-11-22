net = require 'net'
{ EventEmitter } = require 'events'
u = require './utilities'
Consumable = require './consumable'

VER =
  SOCKS5: 0x05

AUTH =
  NOAUTH: 0x00

CMD =
  CONNECT: 0x01
  BIND: 0x02

ADDRTYPE =
  IPV4: 0x01
  DOMAIN: 0x03
  IPV6: 0x04

STATUS =
  SUCCESS: 0x00

RSV = 0x00

class SocksServer extends EventEmitter
  constructor: ->
    super

    @server = net
      .createServer (clientConnection) =>
        @_awaitData clientConnection, @_authenticationHandler
      .on 'listening', =>
        @emit 'listening'
      .on 'close', =>
        @emit 'close'
      .on 'error', (err) =>
        @emit 'error', err

  _awaitData: (clientConnection, callback) =>
    clientConnection.once 'data', (chunk) =>
      callback clientConnection, (new Consumable chunk)

  _authenticationHandler: (clientConnection, data) =>
    version = data.byte()
    nmethods = data.byte()
    methods = (data.byte() for i in [0...nmethods])

    clientConnection.write new Buffer [
      VER.SOCKS5
      AUTH.NOAUTH
    ]

    @_awaitData clientConnection, @_requestHandler

  _requestHandler: (clientConnection, data) =>
    version = data.byte()
    command = data.byte()
    rsv = data.byte()
    addressType = data.byte()
    host =
      switch addressType
        when ADDRTYPE.IPV4 then u.formatIPv4 (data.byte 4)
        when ADDRTYPE.IPV6 then u.formatIPv6 (data.byte 16)
        when ADDRTYPE.DOMAIN then data.char data.byte()
    port = data.uint16()

    clientConnection.write new Buffer [
      VER.SOCKS5
      STATUS.SUCCESS
      RSV
      ADDRTYPE.IPV4
      (u.parseIPv4 clientConnection.localAddress)...
      (u.toUInt16BE clientConnection.localPort)...
    ]

    @emit 'connection', clientConnection, { host, port }

  listen: (args...) =>
    @server.listen args...

  close: (args...) =>
    @server.close args...

  address: =>
    @server.address()

  unref: =>
    @server.unref()

  ref: =>
    @server.ref()

module.exports =
  createServer: (callback) ->
    server = new SocksServer
    server.on 'connection', callback
    return server

  Server: SocksServer
