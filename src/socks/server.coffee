net = require 'net'
{ EventEmitter } = require 'events'
u = require '../utilities'
Consumable = require '../consumable'
{ VER, AUTH, CMD, ADDRTYPE, STATUS, RSV } = require './const'

module.exports = class Server extends EventEmitter
  methods: ['getConnections', 'listen', 'close', 'address', 'unref', 'ref']

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

    @[method] = @server[method].bind @server for method in @methods

  _awaitData: (clientConnection, callback) =>
    clientConnection.once 'data', (chunk) =>
      callback clientConnection, (new Consumable chunk)

  _authenticationHandler: (clientConnection, data) =>
    version = data.byte()

    if version isnt VER.SOCKS5
      @emit 'clientError', (new Error "Wrong client version (#{version})"), data.buffer
      clientConnection.destroy()
      return

    nmethods = data.byte()
    methods = (data.byte() for i in [0...nmethods])

    if AUTH.NOAUTH in methods
      auth = AUTH.NOAUTH
    else
      auth = AUTH.NO_ACCEPTABLE_METHOD
      @emit 'clientError', (new Error "No acceptable methods (#{methods.join ', '})"), data.buffer

    clientConnection.write new Buffer [
      VER.SOCKS5
      auth
    ]

    @_awaitData clientConnection, @_requestHandler

  _requestHandler: (clientConnection, data) =>
    version = data.byte()
    if version isnt VER.SOCKS5
      @emit 'clientError', (new Error "Wrong client version (#{version})"), data.buffer
      clientConnection.destroy()
      return

    command = data.byte()
    if command isnt CMD.CONNECT
      clientConnection.write new Buffer [
        VER.SOCKS5
        STATUS.NOT_SUPPORTED
      ]
      @emit 'clientError', (new Error "Unsupported command (#{command})"), data.buffer
      clientConnection.destroy()
      return

    rsv = data.byte()
    addrType = data.byte()
    if addrType not in [ADDRTYPE.IPV4, ADDRTYPE.IPV6, ADDRTYPE.DOMAIN]
      @emit 'clientError', (new Error "Unsupported address type (#{addrType})"), data.buffer
      clientConnection.destroy()
      return

    host =
      switch addrType
        when ADDRTYPE.IPV4 then u.formatIPv4 (data.read 4)
        when ADDRTYPE.IPV6 then u.formatIPv6 (data.read 16)
        when ADDRTYPE.DOMAIN then data.char data.byte()
    port = data.uint16()

    { localAddress, localPort } = clientConnection

    @emit 'request', clientConnection, host, port, (status) ->
      if status and status isnt STATUS.SUCCESS
        clientConnection.write new Buffer [
          VER.SOCKS5
          status
        ]
        clientConnection.destroy()
        return

      clientConnection.write new Buffer [
        VER.SOCKS5
        STATUS.SUCCESS
        RSV
        ADDRTYPE.IPV4
        (u.parseIPv4 localAddress)...
        (u.toUInt16BE localPort)...
      ]
