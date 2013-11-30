{ EventEmitter } = require 'events'

# Straight up stolen from Marak/colors.js
DEFAULT_STYLES =
  default: []

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

CLOSE_CODES = 
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

class Node extends EventEmitter
  constructor: ({ @type, @open, @close }) ->
    super()

    @type or= 'root'
    @children or= []
    @open or= []
    @close or= []
    @length or= 0

  append: (child) ->
    @length += child.length
    @children.push child

    @emit 'append', child
    child.on 'append', (child) =>
      @length += child.length
      @emit 'append', child

  appendCodes: (codes) ->
    for code in codes
      @open.push code 
      @close.unshift CLOSE_CODES[code]

  style: ->
    @_style().join ''

  _style: ->
    throw new Error 'Not implemented'

  copy: ->
    throw new Error 'Not implemented'

  slice: (start = 0, end = Infinity) ->
    copy = @copy()

    copy.splice start, end

    return copy

  splice: ->
    throw new Error 'Not implemented'

class TextNode extends Node
  constructor: (@value, opts = {}) ->
    opts.type = 'text'
    super opts

    @length = value.length

  _style: ->
    return [unescape @value]

  copy: ->
    copy = new TextNode @value, type: @type, open: @open[..], close: @close[..]
    return copy

  splice: (start = 0, end = Infinity) ->
    @value = @value[start...end]
    @length = @value.length

    return @

class TagNode extends Node
  constructor: (@name, opts = {}) ->
    opts.type = 'tag'
    super opts

  _style: ->
    return if @children.length is 0
    output = []

    # Apply open codes.
    output.push code for code in @open

    # Push child nodes.
    for childNode in @children
      output = output.concat childNode._style()
      # Reapply own styles
      output = output.concat @open

    # Apply close codes.
    output.push code for code in @close

    return output

  copy: ->
    copy = new TagNode @tag, type: @type, open: @open[..], close: @close[..]
    copy.append child.copy() for child in @children 
    return copy

  splice: (start = 0, end = Infinity) ->
    index = 0

    for child, i in @children
      newIndex = index + child.length
      if index + child.length < start
        @children.shift()
        @length -= child.length

      else
        if newIndex >= end
          @length -= child.length
          child.splice 0, end - index
          @length += child.length

        if start > index and start < newIndex
          @length -= child.length
          child.splice start - index
          @length += child.length

        if newIndex == end
          break

    return @

class Logger
  constructor: (options = {}) ->
    @options = {}
    @options[name] = value for own name, value of options

    @_styles = {}
    @_styles[name] = value[..] for name, value of DEFAULT_STYLES

    @_events = {}
    @_modes = {}

    @options.tab or= 6
    @options.gutter = ' - ' if not @options.gutter and @options.gutter isnt ''
    @options.gutter = @parse @options.gutter

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

  emit: (event, data) =>
    return if @_mode? and @_modes[@_mode] isnt true and (@_mode is false or event not in @_modes[@_mode])

    event = @_events[event] or (@parse event)
    data = @format data

    output = []

    dataLines = data.split '\n'
    eventLines =
      for i in [0...(Math.ceil event.length / @options.tab)]
        event.slice i * @options.tab, (i + 1) * @options.tab

    tabsSpace = (new Array @options.tab + 1).join(' ')
    gutterSpace = (new Array @options.gutter.length + 1).join(' ')
    gutter = @options.gutter.style()

    for i in [0...(Math.max dataLines.length, eventLines.length)]
      line = []
      eventLine = eventLines[i]
      dataLine = dataLines[i]

      if eventLine
        line.push (new Array @options.tab - eventLine.length + 1).join(' ')
        line.push eventLine.style()
      else
        line.push tabsSpace

      line.push if i is 0 then gutter else gutterSpace
      line.push dataLine

      output.push (line.join '')

    console.log (output.join '\n')

    return @

  format: (str) =>
    (@parse str).style()

  parse: (str) ->
    reg = /<\/?[a-zA-Z0-9-]*>/g

    output = []
    lastIndex = 0
    matchesLength = 0

    tree = []

    root = new TagNode 'root',
      open: @_styles.default[..] or []
      close: (CLOSE_CODES[code] for code in @_styles.default by -1)

    tree.unshift root

    while match = reg.exec str
      { 0: match, index } = match

      # Create a text node with the text in between the two tags.
      tree[0].append new TextNode str[lastIndex...index] if str[lastIndex...index] isnt ''
      lastIndex = index + match.length

      open = match[1] isnt '/'
      tag = if open then match[1...-1] else match[2...-1]

      if open
        node = new TagNode tag
        tree[0].append node

        # Retrieve codes associated with this tag
        if (tag.indexOf '-') isnt -1
          for style in (tag.split '-')
            throw new Error "Non-existent style #{style} at index #{index}" if style not of @_styles
            node.appendCodes @_styles[style]
        else
          throw new Error "Non-existent style #{tag} at index #{index}" if tag not of @_styles
          node.appendCodes @_styles[tag]

        tree.unshift node

      # Else, close the node by removing it from the tree.
      else
        node = tree.shift()

        throw new Error "Expected </#{node.name}> or </> closing tag, received </#{tag}> instead at index #{index}" if node.name isnt tag and match isnt '</>'

    # Create a text node with the remaining text
    tree[0].append new TextNode str[lastIndex..]

    return root

  setMode: (mode) ->
    throw (new Error "Unknown mode (#{mode})") if mode not of @_modes
    @_mode = mode
    return @

  registerMode: (name, events) ->
    @_mode or= name if name is 'default'
    @_modes[name] = events
    return @

  registerEvent: (name, display) ->
    @_events[name] = @parse display
    return @

  registerStyle: (name, styles) ->
    @_styles[name] = [].concat (@_styles[style] for style in styles)...
    return @

Logger.Node = Node
Logger.TagNode = TagNode
Logger.TextNode = TextNode

module.exports = Logger
