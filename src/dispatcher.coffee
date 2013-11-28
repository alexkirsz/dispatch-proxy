module.exports = class Dispatcher
  constructor: (@addresses) ->
    @connectionsTotal = 0
    @connectionsByAddress = {}
  
  prioritiesSum: ->
    (priority for { priority } in @addresses).reduce (a, b) -> a + b

  dispatch: ->
    availableAddress = null # Address whose priority is least respected.
    prevailingAddress = null # Address with the highest priority.
    maxRatioDiff = 0
    maxPriority = 0

    for address in @addresses
      currentRatio = (@connectionsByAddress[address.address] / @connectionsTotal) or 0
      priorityRatio = address.priority / @prioritiesSum()
      ratioDiff = priorityRatio - currentRatio

      if ratioDiff > maxRatioDiff
        maxRatioDiff = ratioDiff
        availableAddress = address.address
      if address.priority > maxPriority
        maxPriority = address.priority
        prevailingAddress = address.address

    # If the maxDiff approaches zero, it means that all address priorities are currently respected.
    if maxRatioDiff < 0.000001
      @_dispatch prevailingAddress
      return prevailingAddress
    else
      @_dispatch availableAddress
      return availableAddress

  _dispatch: (address) ->
    @connectionsByAddress[address] or= 0
    @connectionsByAddress[address]++
    @connectionsTotal++

  free: (address) =>
    @connectionsTotal--
    delete @connectionsByAddress[address] if --@connectionsByAddress[address] is 0

