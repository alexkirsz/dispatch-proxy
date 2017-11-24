{ EventEmitter } = require 'events'

module.exports = class Dispatcher extends EventEmitter
  constructor: (@addresses) ->
    super()
    @connectionsTotal = 0
    @connectionsByAddress = {}
    @_listByTraffic = []
    @_listByLatency = []
  
  _prioritiesSum: ->
    (priority for { priority } in @addresses).reduce (a, b) -> a + b

  dispatch: ->
    availableAddress = null # Address whose priority is least respected.
    prevailingAddress = null # Address with the highest priority.
    maxRatioDiff = 0
    maxPriority = 0
    for address in @addresses
      currentRatio = (@connectionsByAddress[address.address] / @connectionsTotal) or 0
      priorityRatio = address.priority / @_prioritiesSum()
      ratioDiff = priorityRatio - currentRatio


      if ratioDiff > maxRatioDiff
        maxRatioDiff = ratioDiff
        availableAddress = address.address
      if address.priority > maxPriority
        maxPriority = address.priority
        prevailingAddress = address.address

      #Least Traffic 
      sorted = _listByTraffic.sort(@sorter)
      console.log(sorted)

      if sorted[0] == sorted[address]
        @_increment address
        return address

      #Least Latency


    # If the maxDiff approaches zero, it means that all address priorities are currently respected.
    if maxRatioDiff < 0.000001
      @_increment prevailingAddress
      return prevailingAddress
    else
      @_increment availableAddress
      return availableAddress

  _increment: (address) ->
    @connectionsByAddress[address] or= 0
    @connectionsByAddress[address]++
    @connectionsTotal++
    @_listByTraffic[address]++

  free: (address) =>
    @connectionsTotal--
    delete @connectionsByAddress[address] if --@connectionsByAddress[address] is 0

sorter: (a,b) ->
  return a.id - b.id