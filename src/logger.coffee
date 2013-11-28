module.exports = class Logger
  # Straight up stolen from Marak/colors.js
  codes:
    bold: ['\x1B[1m']
    italic: ['\x1B[3m']
    underline: ['\x1B[4m']
    inverse: ['\x1B[7m']
    strikethrough: ['\x1B[9m']

    white: ['\x1B[37m']
    grey: ['\x1B[90m']
    black: ['\x1B[30m']
    blue: ['\x1B[34m']
    cyan: ['\x1B[36m']
    green: ['\x1B[32m']
    magenta: ['\x1B[35m']
    red: ['\x1B[31m']
    yellow: ['\x1B[33m']

    whiteBG: ['\x1B[47m']
    greyBG: ['\x1B[49;5;8m']
    blackBG: ['\x1B[40m']
    blueBG: ['\x1B[44m']
    cyanBG: ['\x1B[46m']
    greenBG: ['\x1B[42m']
    magentaBG: ['\x1B[45m']
    redBG: ['\x1B[41m']
    yellowBG: ['\x1B[43m']

  _closes:
    '\x1B[1m': '\x1B[22m'
    '\x1B[3m': '\x1B[23m'
    '\x1B[4m': '\x1B[24m'
    '\x1B[7m': '\x1B[27m'
    '\x1B[9m': '\x1B[29m'

    '\x1B[37m': '\x1B[39m'
    '\x1B[90m': '\x1B[39m'
    '\x1B[30m': '\x1B[39m'
    '\x1B[34m': '\x1B[39m'
    '\x1B[36m': '\x1B[39m'
    '\x1B[32m': '\x1B[39m'
    '\x1B[35m': '\x1B[39m'
    '\x1B[31m': '\x1B[39m'
    '\x1B[33m': '\x1B[39m'

    '\x1B[47m': '\x1B[49m'
    '\x1B[49;5;8m': '\x1B[49m'
    '\x1B[40m': '\x1B[49m'
    '\x1B[44m': '\x1B[49m'
    '\x1B[46m': '\x1B[49m'
    '\x1B[42m': '\x1B[49m'
    '\x1B[45m': '\x1B[49m'
    '\x1B[41m': '\x1B[49m'
    '\x1B[43m': '\x1B[49m'

  constructor: (options = {}) ->
    @options = {}
    @options[name] = value for own name, value of options

    @options.tab or= 6
    @options.gutter or= ' - '
    gutter = @_parse @options.gutter
    @options.gutter = @_style gutter
    @options.gutterLength = gutter.textLength

    @_events = {}
    @_modes = {}

  log: (data, options = {}) =>
    { colors, depth, showHidden } = options
    colors ?= true

    if typeof data is 'string'
      console.log @format data
    else if typeof data in ['object', 'number']
      console.log (util.inspect data, { depth, showHidden, colors })
    else
      console.log data

    return @

  emit: (event, data, options = {}) =>
    return if @_mode? and @_modes[@_mode] isnt true and (@_mode is false or event not in @_modes[@_mode])

    event = if @_events[event] then @_events[event] else @_parse event
    data = if options.raw then data else @format data

    output = []

    dataLines = data.split '\n'
    eventLines = ((@_slice event, i * @options.tab, (i + 1) * @options.tab) for i in [0...(Math.ceil event.textLength / @options.tab)])

    tabs = (new Array @options.tab + 1).join(' ')
    for i in [0...(Math.max dataLines.length, eventLines.length)]
      line = []
      if eventLines[i]
        line.push (new Array @options.tab - eventLines[i].textLength + 1).join(' ')
        line.push (@_style eventLines[i])
      else
        line.push tabs
      line.push if i is 0 then @options.gutter else (new Array @options.gutterLength + 1).join(' ')
      line.push dataLines[i]
      output.push (line.join '')

    console.log (output.join '\n')

    return @

  setMode: (mode) ->
    throw (new Error "Unknown mode (#{mode})") if mode not of @_modes
    @_mode = mode
    return @

  registerMode: (name, events) ->
    @_mode or= name if name is 'default'
    @_modes[name] = events
    return @

  registerEvent: (name, display) ->
    @_events[name] = @_parse display
    return @

  registerStyle: (name, styles) ->
    if @codes is Logger::codes
      @codes = {}
      @codes[_name] = value for _name, value of Logger::codes

    @codes[name] = [].concat (@codes[style] for style in styles)...
    return @

  format: (str) ->
    @_style (@_parse str)

  _parse: (str) ->
    reg = /<\/?.*?>/g

    output = []
    lastIndex = 0
    matchesLength = 0

    rootNode =
      type: 'root'
      textLength: 0
      children: []
      openCodes: @codes.default?[..] or []
      closeCodes: if @codes.default then (@_closes[code] for code in @codes.default by -1) else []

    parentNode = rootNode

    textNode = (value) ->
      return if value is ''

      node =
        type: 'text'
        value: value
        index: lastIndex - matchesLength
        parent: parentNode

      node.parent.textLength += node.value.length
      node.parent.children.push node

    while match = reg.exec str
      { 0: match, index } = match

      # Create a text node with the text in between two tags.
      textNode str[lastIndex...index]

      open = match[1] isnt '/'
      tag = if open then match[1...-1] else match[2...-1]

      # If the tag is an open tag, create a new node and set it as current parent.
      if open
        node =
          type: 'tag'
          name: tag
          parent: parentNode
          textLength: 0
          children: []
          openCodes: if parentNode.type is 'root' then [] else parentNode.openCodes[..]
          closeCodes: if parentNode.type is 'root' then [] else parentNode.closeCodes[..]

        # Retrieve codes associated with this tag.
        if (tag.indexOf '-') isnt -1
          for style in (tag.split '-')
            throw new Error "Non-existent style #{style} at index #{index}" if style not of @codes
            for code in @codes[style]
              node.openCodes.push code 
              node.closeCodes.unshift @_closes[code]
        else
          throw new Error "Non-existent style #{tag} at index #{index}" if tag not of @codes
          for code in @codes[tag]
            node.openCodes.push code 
            node.closeCodes.unshift @_closes[code]

        node.parent.children.push node
        parentNode = node

      # Else, close the node by setting its parent as current parent.
      else
        [node, parentNode] = [parentNode, parentNode.parent]
        throw new Error "Expected </#{node.name}> or </> closing tag, received </#{tag}> instead at index #{index}" if node.name isnt tag and match isnt '</>'
        node.parent.textLength += node.textLength

      lastIndex = index + match.length
      matchesLength += match.length

    # Create a text node with the remaining text
    textNode str[lastIndex..]

    # Close remaining tags.
    while parentNode.type isnt 'root'
      [node, parentNode] = [parentNode, parentNode.parent]
      node.parent.textLength += node.textLength

    return rootNode

  _style: (node) ->
    output = do style = (node = node) ->
      switch node.type
        when 'root', 'tag'
          return if node.children.length is 0
          output = []

          # Apply open codes.
          output.push code for code in node.openCodes

          # Push child nodes.
          output = output.concat (style childNode for childNode in node.children)...

          # Apply close codes.
          output.push code for code in node.closeCodes

          # Re-apply parent styles.
          output.push code for code in node.parent.openCodes unless node.type is 'root'

        when 'text'
          output = [node.value]

      return output

    return output.join ''

  _slice: (node, start = 0, end = Infinity) ->
    return do slice = (parent = undefined, node = node) ->
      _node = {}
      _node[name] = value for name, value of node
      _node.parent = parent
      _node.children = []

      switch node.type
        when 'root', 'tag'

          _node.textLength = 0

          for childNode in node.children
            _childNode = slice _node, childNode, start, end
            # Only append the node if it isn't empty.
            _node.children.push _childNode if _node.textLength isnt 0

          _node.parent.textLength += _node.textLength unless _node.type is 'root'

        when 'text'
          _start = start - node.index
          _start = node.value.length if _start > node.value.length
          _start = 0 if _start < 0
          _end = end - node.index
          _end = node.value.length if _end > node.value.length
          _end = 0 if _end < 0

          _node.index = node.index - start
          _node.index = 0 if _node.index < 0
          _node.value = node.value[_start..._end]
          _node.parent.textLength += _node.value.length

      return _node
