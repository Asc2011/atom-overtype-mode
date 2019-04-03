{ CompositeDisposable } = require 'atom'


class OvertypeMode

  active    : false
  cmds      : new CompositeDisposable()
  events    : new CompositeDisposable()
  config    : require './config.coffee'
  className : 'overtype-cursor'

  # TODO filter the commands and activate only according user-settings

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
        pasteOver : () => @pasteOver()
      }

    @events.add(
      atom.workspace.observeTextEditors (editor) =>
        @prepareEditor editor
    )


  cfg: (key) ->
    atom.config.get 'atom-overtype-mode.' + key

  activeEditor: ->
    atom.workspace.getActiveTextEditor()

  consumeStatusBar: (statusBar) ->

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


  backspace: ->
    editor = @activeEditor()
    @info editor

    normalBS = -> editor.backspace()

    unless @active then return normalBS()
    unless @cfg 'changedBackspace' then return normalBS()

    cursor = editor.getLastCursor()
    return if cursor.isAtBeginningOfLine()

    editor.selectLeft()
    editor.mutateSelectedText (sel, idx) ->
      sel.insertText ' ', select: yes
      sel.clear()


  delete: ->
    editor = @activeEditor()
    # @info editor

    if @active and @cfg 'changedDelete'

      # cycle thru all selections
      for sel in editor.getSelections()
        txt = sel.getText()
        if txt.length > 1
          # prepare replacement-spaces
          spaces = Array( txt.length ).join ' '
          range = sel.getScreenRange()
          sel.insertText spaces
          cursor = editor.getLastCursor()
          # place caret to the beginning of the replacement
          cursor.setScreenPosition [
            range.start.row
            range.start.column
          ]
        else
          editor.delete()
          editor.insertText ' '
          editor.moveLeft()
    else
      # standard-mode
      editor.delete()


  pasteOver: ->
    editor = @activeEditor()

    unless @active
      return editor.pasteText()

    text = atom.clipboard.read()
    return if text.length is 0

    editor.selectRight text.length
    range = editor.insertText text

    console.log "insertText gave", range


  onType: (editor) ->
    return unless @active
    # Only trigger when user types manually
    return unless window.event instanceof TextEvent

    for selection in editor.getSelections()
      continue if selection.isEmpty() && selection.cursor.isAtEndOfLine()
      if selection.isEmpty()
        selection.selectRight()

module.exports = new OvertypeMode
