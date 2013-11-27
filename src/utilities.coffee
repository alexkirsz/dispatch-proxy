exports.toUInt16LE = (value) -> [value & 0x00ff, (value & 0xff00) >>> 8]
exports.toUInt16BE = (value) -> [(value & 0xff00) >>> 8, value & 0x00ff]
exports.toUInt32LE = (value) -> [value & 0xff, (value >>> 8) & 0xff, (value >>> 16) & 0xff, (value >>> 24) & 0xff]
exports.toUInt32BE = (value) -> [(value >>> 24) & 0xff, (value >>> 16) & 0xff, (value >>> 8) & 0xff, value & 0xff]

exports.formatIPv4 = (value) -> Array::join.call value, '.'

exports.formatIPv6 = (value) ->
  if not Buffer.isBuffer value
    value = new Buffer value
  ("#{value[i..i + 1].toString 'hex'}" for i in [0...value.length] by 2).join ':'

exports.parseIPv4 = (value) -> (value.split '.').map (v) -> parseInt v, 10

exports.parseIPv6 = (value) ->
  output = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  offset = 0
  parts = value.split ':'
  for part in parts
    if part
      output[offset...offset + 2] = exports.toUInt16BE (parseInt part, 16)
      offset += 2
    else
      offset += 16 - (parts.length * 2 - offset)
  output
