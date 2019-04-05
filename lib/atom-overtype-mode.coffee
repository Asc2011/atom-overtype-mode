
{ CompositeDisposable } = require 'atom'

actions = require './actions.coffee'


class OvertypeMode

  active    : no
  cmds      : new CompositeDisposable()
  events    : new CompositeDisposable()
  config    : require './config.coffee'
  className : 'overtype-cursor'

  # TODO filter the commands and activate only according 
  # to user-settings. Plus observe changes to config-settings.
 
  activate: (state) ->

    @cmds.add(
      atom.commands.add(
        'atom-text-editor',
        'overtype-mode:' + cmd,
        method
      )
    ) for cmd, method of {
        toggle    : () => @toggle()
        delete    : () => @delete()
        backspace : () => @backspace()
        paste     : () => @paste()
      }

    @events.add(
      atom.workspace.observeTextEditors (editor) =>
        @prepareEditor editor
    )


  cfg: (key) ->
    atom.config.get 'atom-overtype-mode.' + key

  activeEditor: ->
    atom.workspace.getActiveTextEditor()

  consumeStatusBar: ( statusBar ) ->

    @sbItem?.dispose()

    if 'no' isnt @cfg 'showIndicator'
      @sbItem = document.createElement 'div'
      @sbItem.classList.add 'inline-block'
      @sbItem.classList.add 'mode-insert'
      @sbItem.textContent = 'INS'
      @sbItem.addEventListener 'click', => @toggle()

      @sbTooltip?.dispose()
      @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'

    if 'left' == @cfg 'showIndicator'
      @sbTile = statusBar.addLeftTile
        item     : @sbItem
        priority : 50
    else if 'right' == @cfg 'showIndicator'
      @sbTile = statusBar.addRightTile
        item     : @sbItem
        priority : 50

    @enable() if 'overwrite' == @cfg 'startMode'


  deactivate: ->
    @disable()
    @events.dispose()
    @cmds.dispose()

    @sbItem?.destroy()
    @sbTile?.destroy()
    if @sbItem?
      @sbItem = null
      @sbTile = null


  toggle: ->
    if @active then @disable()
    else @enable()

    @updateCursorStyle() if @cfg 'changeCaretStyle'


  enable: ->
    @active = yes
    return if 'no' == @cfg 'showIndicator'

    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Overwrite'
    @sbItem.textContent = 'DEL'
    @sbItem.classList.remove 'mode-insert'
    @sbItem.classList.add    'mode-overwrite'


  disable: ->
    @active = no
    return if 'no' == @cfg 'showIndicator'

    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'
    @sbItem.textContent = 'INS'
    @sbItem.classList.remove 'mode-overwrite'
    @sbItem.classList.add    'mode-insert'


  updateCursorStyle: ->
    return unless @cfg 'changeCaretStyle'

    for editor in atom.workspace.getTextEditors()

      view = atom.views.getView editor
      if @active
        view.classList.add @className
      else
        view.classList.remove @className


  prepareEditor: (editor) ->
    
    if @cfg 'changedReturn'
      unless editor._insertNewline?
        editor._insertNewline = editor.insertNewline
        editor.insertNewline = => @enter()
      
    @updateCursorStyle()
    
    @events.add(
      editor.onWillInsertText => @onType editor
    )


  info: (editor) ->
    log = console.log
    log "multiple cursors", editor.hasMultipleCursors()
    selectedText = editor.getSelectedText()
    sels = editor.getSelections()
    log "has #{sels.length}-selection-len=#{selectedText.length} '#{selectedText}'"
    for sel, i in sels
      log "\tsel-#{i}", sel.getScreenRange()
      


  onType: (editor) ->
    return unless @active
    #
    # only trigger when user types manually
    #
    return unless window.event instanceof TextEvent
    
    for selection in editor.getSelections()
      continue if selection.isEmpty() && selection.cursor.isAtEndOfLine()
      if selection.isEmpty()
        selection.selectRight()


#
# inject the implementations of behaviours.
#
# TODO make this smarter and check if enabled by settings.
#
for key, action of actions
  OvertypeMode::[key] = action

module.exports = new OvertypeMode
