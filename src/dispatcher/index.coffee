net = require 'net'
{ EventEmitter } = require 'events'
socks = require './socks'

module.exports = class Dispatcher extends EventEmitter
  constructor: (@addresses, port, host) ->
    @connectionsTotal = 0
    @connectionsByAddress = {}

  dispatchAddress: =>
    availableAddress = null # Address whose priority is least respected.
    prevailingAddress = null # Address with the highest priority.
    maxRatioDiff = 0
    maxPriority = 0

    prioritiesTotal = (priority for { priority } in @addresses).reduce (a, b) -> a + b

    for localAddress in @addresses
      currentRatio = (@connectionsByAddress[localAddress.address] / @connectionsTotal) or 0
      priorityRatio = localAddress.priority / prioritiesTotal
      ratioDiff = priorityRatio - currentRatio

      if ratioDiff > maxRatioDiff
        maxRatioDiff = ratioDiff
        availableAddress = localAddress
      if priority > maxPriority
        maxPriority = priority
        prevailingAddress = localAddress

    # If the maxDiff approaches zero, it means that all address priorities are currently respected.
    if maxRatioDiff < 0.000001
      return prevailingAddress
    else
      return availableAddress
