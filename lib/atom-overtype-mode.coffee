log = console.log  

{ CompositeDisposable } = require 'atom'

actions = require './actions.coffee'
pkg     = require '../package.json'

class OvertypeMode

  statusBar   : null # holds a reference to the status-bar.
  minComplete : atom.config.get 'autocomplete-plus.minimumWordLength'
  cmds        : new CompositeDisposable()
  events      : new CompositeDisposable()
  config      : require './config.coffee'
  caretClass  : 'overtype-cursor'
  enabledEd   : new Set() # keeps editor-instance-id's
  gcEditors   : -> # garbage collect TextEditor-instances
    ids = atom.workspace.getTextEditors().map (e) -> e.id
    for id in Array.from @enabledEd
      unless id in ids
        @enabledEd.delete id
  active      : (editor) ->  # is given editor active ?
    unless editor?
      editor = @activeEditor()
      return unless editor?
    editor if @enabledEd.has editor.id
  
  settingsObserver: (setting) ->
    
    switch setting.key
      
      when 'showIndicator'
        if setting.new is 'no'
          @sbItem.classList.add 'hide-indicator'
        else
          @consumeStatusBar @statusBar
          
      when 'changeCaretStyle'
        @updateCursorStyle()
      
      else
        console.log "no action for '#{setting.key}'"


  activate: (state) ->
    
    # st = atom.config.get 'editor.atomicSoftTabs'
    # log "atomicSoftTabs active 11 ? ", st
    
    @events.add(
      atom.config.onDidChange pkg.name, ({ oldValue, newValue }) =>

        for key, val of newValue
          unless oldValue[key] is val
            setting =
              key     : key
              old     : oldValue[ key ]
              new     : val
              
            break
            
        console.log 'change was', setting
        
        @settingsObserver setting
    )
    
    # TODO filter the commands and activate only according 
    # to user-settings. 
    #
    @cmds.add(
      atom.commands.add(
        'atom-text-editor',
        'overtype-mode:' + cmd,
        method
      )
    ) for cmd, method of {
        toggle            : () => @toggle()
        delete            : () => @delete()
        backspace         : () => @backspace()
        paste             : () => @paste()  
        duplicateLines    : () => @duplicateLines()
        pasteLikeLawrence : () => @pasteLikeLawrence()
        smartInsert       : () => @smartInsert()
        backspace2col0    : () => @backspace2col0()
        backspace2lastcol : () => @backspace2lastcol()
      }

    @events.add(
      atom.workspace.observeTextEditors (editor) =>
        @prepareEditor editor
    )
    
    @events.add(
      atom.workspace.onDidChangeActiveTextEditor (editor) =>
        return unless editor?

        if @active editor
          @enable()
        else @disable()
          
        @gcEditors()
    )
    

  cfg: (key) ->
    atom.config.get [ pkg.name, key ].join '.'

  activeEditor: ->
    atom.workspace.getActiveTextEditor()


  consumeStatusBar: ( statusBar ) ->
    @statusBar = statusBar
    @setupIndicator()
    @enable() if 'overwrite' is @cfg 'startMode'

  getLineEnding: ->
    
    codes = { 'LF': '\n', 'CRLF': '\r\n' }
    
    tiles = @statusBar.getRightTiles()
    for tile in tiles.concat @statusBar.getLeftTiles()
      continue unless tile.item?.element?.classList?.contains 'line-ending-tile'
      lineEnding = tile.item.element.text
      break

    codes[ lineEnding or 'LF' ]


  setupIndicator: ->
    
    unless @sbItem?
      @sbItem = document.createElement 'div'
      @sbItem.classList.add 'inline-block'
      @sbItem.classList.add 'mode-insert'
      @sbItem.textContent = 'INS'
      @sbItem.addEventListener 'click', => @toggle()
      @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'
    
    @sbTile.destroy() if @sbTile?
    
    switch @cfg 'showIndicator'
      
      when 'left'
        @sbItem.classList.remove 'hide-indicator'
        @sbTile = @statusBar.addLeftTile
          item     : @sbItem
          priority : 50
          
      when 'right'
        @sbItem.classList.remove 'hide-indicator'
        @sbTile = @statusBar.addRightTile
          item     : @sbItem
          priority : 50
          
      when 'no'
        @sbItem.classList.add 'hide-indicator'


  deactivate: ->
    
    @disable()
    @events.dispose()
    @cmds.dispose()

    @sbTile?.destroy()
    @sbItem = null if @sbItem?
    
    atom.workspace.getTextEditors().map (editor) ->
      if editor.pristine_insertNewline?
        editor.enter = editor.pristine_insertNewline
        editor.pristine_insertNewline = null
    
    @enabledEd.clear()


  toggle: ->
    return unless editor = @activeEditor()
    
    @getLineEnding()

    if @active editor
      @enabledEd.delete editor.id
      @disable()
    else
      @enabledEd.add editor.id
      @enable()

    @updateCursorStyle() if @cfg 'changeCaretStyle'
    
    console.log 'toggle::', @enabledEd.size, Array.from @enabledEd


  enable: ->
    return if 'no' == @cfg 'showIndicator'
  
    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Overwrite'
    @sbItem.textContent = 'DEL'
    @sbItem.classList.remove 'hide-indictator' if @hidden
    @sbItem.classList.remove 'mode-insert'
    @sbItem.classList.add    'mode-overwrite'


  disable: ->
    return if 'no' == @cfg 'showIndicator'

    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'
    @sbItem.textContent = 'INS'
    @sbItem.classList.remove 'hide-indictator' if @hidden
    @sbItem.classList.remove 'mode-overwrite'
    @sbItem.classList.add    'mode-insert'


  updateCursorStyle: ->
    return unless @cfg 'changeCaretStyle'

    for editor in atom.workspace.getTextEditors()

      view = atom.views.getView editor
      if @active editor
        view.classList.add @caretClass
      else
        view.classList.remove @caretClass


  prepareEditor: (editor) ->
    
    if @cfg 'changedReturn'
    
      unless editor.pristine_insertNewline?
        editor.pristine_insertNewline = editor.insertNewline
        editor.insertNewline = => @enter()
        
      
    editor.observeSelections (sel) =>
      
      unless sel.pristine_insertText?
        sel.pristine_insertText = sel.insertText
        
      isAutocompleteInsert = (sel, txt) =>
        minLen = @minComplete
        selTxt = sel.getText()
        selLen = selTxt.length
        txtLen = txt.length
        log "autocomplete-test:: #{selLen} #{minLen}"
        
        ( minLen <= selLen <= txtLen ) and ( txt.startsWith selTxt )


      fitsCurrentLine = (sel, selLen, txtLen) ->
        
        { start } = sel.getBufferRange()
        lineLen   = sel.editor.lineTextForBufferRow(start.row).length
        
        ( lineLen - start.column + selLen - txtLen ) > 0
        
        
      sel.insertText = ( txt, opts ) =>
        
        # ast = atom.config.get 'editor.atomicSoftTabs'
        # if ast
        #   atom.config.set 'editor.atomicSoftTabs', off
        # 
        # fixAst = ->
        #   atom.config.set 'editor.atomicSoftTabs', ast
          
        unless @active()
          #
          # standard-mode for paste 'selection.insertText'
          #
          return sel.pristine_insertText txt, opts

        else unless @cfg 'enableAutocomplete'
          console.log "auto-complete not active", @cfg 'enableAutocomplete'
          return sel.pristine_insertText txt, opts

        unless isAutocompleteInsert sel, txt
          log "no autocomplete insert detected ?"
          log "'#{txt}'", sel
          return sel.pristine_insertText txt, opts
          
        editor = sel.editor
        selLen = sel.getText().length
        txtLen = txt.length
        prefix = sel.getText()

        editor.mutateSelectedText (sel, idx) =>
          log "sel-#{idx} '#{sel.getText()}'"
          range = sel.getBufferRange()
          
          if sel.isEmpty()
            range.start.column -= prefix.length
            
          p2 = sel.editor.getTextInBufferRange range
          log "p2='#{p2}' == '#{prefix}'", p2 == prefix
          return if p2 isnt prefix
          
          if fitsCurrentLine sel, selLen, txtLen
            # log "fits on line"
            range.end.column += txtLen - p2.length
            res = editor.setTextInBufferRange range, txt
          else
            # log "expands line"
            line = editor.lineTextForBufferRow range.start.row
            range.end.column = line.length
            res = sel.editor.setTextInBufferRange range, txt
          #
          # place caret behind the 
          # new insertion range.
          #
          sel.setBufferRange {
            start : res.end
            end   : res.end 
          }
          res

    
    @updateCursorStyle()
    
    @events.add(
      #
      # This hooks into the TextEditor-instance
      # and handles most regular key-strokes.
      #
      editor.onWillInsertText @onType
    )


  info: (editor) ->
    log = console.log
    log "multiple cursors", editor.hasMultipleCursors()
    selectedText = editor.getSelectedText()
    sels = editor.getSelections()
    log "has #{sels.length}-selection-len=#{selectedText.length} '#{selectedText}'"
    for sel, i in sels
      log "\tsel-#{i}", sel.getScreenRange()


  onType: ( evt ) =>
   
    return unless editor = @active()
    #
    # only trigger when user types manually.
    #
    wEvent = window.event
    log "window-event", wEvent
    
    return unless wEvent instanceof TextEvent
    
    # evt.cancel() if evt.text.length == 2
    
    #atom.config.set 'editor.atomicSoftTabs', off
    log evt
    for sel in editor.getSelections()
      if sel.isEmpty() 
        continue if sel.cursor.isAtEndOfLine()
      
      if evt.text.length == 2
        #
        # TODO better solution ?
        # typically from the bracket-matcher-package
        # quick&dirty solution :
        # use only the first-char..
        #
        evt.cancel()
        theChar = evt.text[0]
        sel.insertText theChar
        sel.cursor.moveRight()
      else
        sel.selectRight()

    #atom.config.set 'editor.atomicSoftTabs', on
#
# inject the implementations of behaviours.
#
# TODO make this smarter and check if enabled by settings.
#
for cmd, action of actions
  OvertypeMode::[cmd] = action

module.exports = new OvertypeMode
