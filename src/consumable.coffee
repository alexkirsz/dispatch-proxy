{ EventEmitter } = require 'events'
fs = require 'fs'

module.exports = class Consumable extends EventEmitter
  @fromFile: (src, endian) ->
    raw = fs.readFileSync src
    new Consumable raw, endian

  constructor: (@buffer, endian = 'BE') ->
    @offset = 0

    @byte = @_read "UInt8", 1
    @int16 = @_read "Int16#{endian}", 2
    @uint16 = @_read "UInt16#{endian}", 2
    @int32 = @_read "Int32#{endian}", 4
    @uint32 = @_read "UInt32#{endian}", 4
    @float = @_read "Float#{endian}", 4
    @double = @_read "Double#{endian}", 8

  read: (n) =>
    @offset += n
    @buffer[@offset - n...@offset]

  move: (n) =>
    @offset += n

  _read: (type, delta) =>
    methodName = "read#{type}"

    return =>
      value = @buffer[methodName] @offset
      @offset += delta
      value

  char: (n = 1) =>
    (@read n).toString 'ascii'
