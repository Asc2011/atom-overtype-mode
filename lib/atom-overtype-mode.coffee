{ CompositeDisposable } = require 'atom'

actions = require './actions'
pkg     = require '../package.json'

cLevel = [ 
  'debug'
  'log'
  'info'
  'warn'
  'error'
]

log = console.log

util =
  deepDiff: (oldV, newV, path=[], diff={} ) ->
    
    for key, val of newV
      #
      if typeof val is 'object'
        path.push key
        # log "recursion on key #{key} #{path.join '.'}"
        diff = util.deepDiff oldV[key], newV[key], path, diff
        path.pop()
      else
        unless oldV[key] is val
          path.push key
          return
            key : path.join '.'
            old : oldV[ key ]
            new : val
    
    unless diff.key?
      msg = """
        util::deepDiff has no diff ?!?
        path '#{path.join '.'}'
      """
      # console.dir oldV
      # console.dir newV
      # log msg
    diff


class OvertypeMode
  
  logLevel    : 4               # current log-level 0=debug...4=error
  levelNames  : []              # Atoms notification-level-names
  statusBar   : null            # holds a ref to the status-bar-obj
  minComplete : atom.config.get 'autocomplete-plus.minimumWordLength'
  cmds        : new CompositeDisposable() # weak-refs
  events      : new CompositeDisposable()
  config      : require './config.coffee' # the settings-view
  caretClass  : 'overtype-cursor'
  enabledEd   : new Set()         # keeps editor-instance-id's
  
  gcEditors   : ->                # garbage collect TextEditor-
    workSpace = atom.workspace    # instances.
    ids = workSpace.getTextEditors().map (e) -> e.id
    for id in Array.from @enabledEd
      unless id in ids
        @enabledEd.delete id
        
  active      : (editor) ->     # has given editor-instance
    unless editor?              # overtype-mode activated ?
      editor = @activeEditor()  # none recieved?, then use active-
      return unless editor?     # instance. Return instance only 
    if @enabledEd.has editor.id # when it has overwrite-mode enabled. 
      return editor
      
  notify      : ( theMsg, level=0 ) ->
    
    msg = [ pkg.name, ':', Date.now(), ': ', theMsg ].join ''
    
    if (level is 4) or @cfg 'Package.debug'
      console[ cLevel[level] ] msg 
    
    return unless level >= @logLevel
    
    levelName = @levelNames[level]
    console.log "levelName '#{levelName}'", levelName, level
    atom.notifications[ 'add' + levelName ] msg
    
  log         : (msg, lvl) -> @notify msg, lvl
  
  settingsObserver: (option) ->
    #
    # Basic switch for changes in our pkg-settings-view, 
    # or settings from other packages, that we are interested in :
    # - 'editor.AtomicSoftTabs' & friends
    # - 'bracket-matcher'
    # - 'autocomplete-plus'
    #
    # currently used for overtype-mode-keys ::
    #
    # - 'atom-overtype-mode.Package.showIndicator'
    # - 'atom-overtype-mode.Package.changeCaretStyle'
    #
    option.key = option.key.split '.'
    
    switch option.key.shift()
      
      when 'Package'
        switch option.key.shift()
      
          when 'showIndicator'
            if option.new is 'no'
              @sbItem.classList.add 'hide-indicator'
            else
              @consumeStatusBar @statusBar
              
          when 'changeCaretStyle'
            @updateCursorStyles()
            
          when 'debug'
            @notify "logging to dev-tools-console = #{option.new}", 1
            if option.new
              atom.confirm
                message: 'Open DevTools-console ?'
                buttons: 
                  Yes: -> atom.openDevTools()
                  No:  -> 
          
          when 'notificationLevel'
            @logLevel = OvertypeMode.levelNames.indexOf option.new
            msg = """
              setting:: #{option.key} was '#{option.old}' now '#{option.new}' => #{@logLevel}
            """
            @log msg, 1
      
      when 'Others'
        switch option.key.shift()
          
          when 'editor'
            switch option.key.shift()
              
              when 'autoIndent'
                keyPath = 'editor.autoIndent'
                atom.config.set keyPath, option.new
              
              when 'atomicSoftTabs'
                keyPath = 'editor.atomicSoftTabs'
                atom.config.set keyPath, option.new

              when 'autoIndentOnPaste'
                keyPath = 'editor.autoIndentOnPaste'
                atom.config.set keyPath, option.new
          
          when 'autocompletePlus'
            switch option.key.shift()
              
              when 'strictMatching'
                keyPath = 'autocomplete-plus.strictMatching'
                atom.config.set keyPath, option.new

              when 'minimumWordLength'
                keyPath = 'autocomplete-plus.minimumWordLength'
                atom.config.set keyPath, option.new

          when 'bracketMatcher'
            switch option.key.shift()
              
              when 'alwaysSkipClosingPairs'
                keyPath = 'bracket-matcher.alwaysSkipClosingPairs'
                atom.config.set keyPath, option.new

              when 'singleCharFilter'
                @notify 'SingleChar-Filter disabled.', 3
                #keyPath = 'bracket-matcher.alwaysSkipClosingPairs'
                #atom.config.set keyPath, option.new

          when 'autocompleteSnippets'
            
            pkgName = 'autocomplete-snippets'
            if option.new is yes
              if atom.packages.isPackageActive pkgName
                atom.packages.disablePackage pkgName
            else
              return if atom.packages.isPackageActive pkgName
              atom.packages.enablePackage pkgName
              
            @log "package 'autocomplete-snippets' is #{option.new}"
      
      else
        @log "no action for '#{option.key}'-section yet."


  activate: (state) ->
    # 
    # overtype-mode-package-activation
    # 
    # st = atom.config.get 'editor.atomicSoftTabs'
    # @log "OMG: atomicSoftTabs active ? ", st
    #
    keyPath = 'Package.notificationLevel'
    schema  = atom.config.getSchema [ pkg.name, keyPath ].join '.'
    
    OvertypeMode.levelNames = schema.enum
    @levelNames = schema.enum
    @logLevel = schema.enum.indexOf @cfg keyPath
    
    @log 'activate::starts'
    
    @events.add(
      # 
      # observe and pre-process changes
      # to the package-settings.
      #
      atom.config.onDidChange pkg.name, ({ oldValue, newValue }) =>
        
        option = util.deepDiff oldValue, newValue
          
        @log "config-change was: '#{Object.values option}'", 1
        #
        # pass the change-object on.
        # 
        @settingsObserver option
    )
    
    # TODO filter the commands and activate only according 
    # to user-settings. 
    #
    @cmds.add(
      #
      # all commands that we want to use from the command-panel
      # or via keyboard-shortcuts.
      # the implementations are from './actions.coffee'
      #
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
        peekBeforePaste   : () => @peekBeforePaste()
      }

    @events.add(
      #
      # Observe & hook into the creation of TextEditor-instances.
      #
      atom.workspace.observeTextEditors (editor) =>
        @log "observe:: new TextEditor id=#{editor.id}"
        @prepareEditor editor
    )
    
    @events.add(
      # 
      # This is for visual-updates to the mode-indicator
      # and cursor-style updates.
      #
      atom.workspace.onDidChangeActiveTextEditor (editor) =>
        return unless editor?
        
        @log "onDidChangeActiveTextEditor is id=#{editor.id}"
        
        if @cfg 'Package.changeCaretStyle'
          @updateCursorStyle editor
        
        if @active editor
          @enable()
        else @disable()
          
        @gcEditors()
    )
    

  cfg: (key) ->
    #
    # shortcut to read a setting-key for 'atom-overtype-mode.'
    #
    atom.config.get [ pkg.name, key ].join '.'

  activeEditor: ->
    #
    # shortcut to get the active-editor.
    #
    atom.workspace.getActiveTextEditor()


  consumeStatusBar: ( statusBar ) ->
    #
    # to use the status-bar-package.
    #
    # keep a handle to the status-bar-obj.
    @statusBar = statusBar
    # 
    @setupIndicator()
    @enable() if 'overwrite' is @cfg 'Package.startMode'


  getLineEnding: ->
    # 
    # reads the line-ending of the current-buffer from
    # the HTML-Tile of the encoding-selector-package.
    # therefore relies on two built-ins-packages :
    #
    # -1- status-bar
    # -2- encoding-selector
    #
    codes = { 'LF': '\n', 'CRLF': '\r\n' }
    
    tiles = @statusBar.getRightTiles()
    #
    # look on the left- and right-side of the status-bar for
    # the encoding-selector.
    #
    for tile in tiles.concat @statusBar.getLeftTiles()
      
      continue unless tile.item?.element?.classList?.contains 'line-ending-tile'
      
      lineEnding = tile.item.element.text
      break
   
    @log "getLineEnding returns '#{lineEnding}'", 1
    
    codes[ lineEnding or 'LF' ]


  setupIndicator: ->
    #
    # setup of the mode-indicator in the status bar.
    # knows three-states :
    # 
    # - 'left'  ->  position on the left-side
    # - 'right' ->  position on the right-sid
    # -  'no'   ->  hidden, invisible
    #
    unless @sbItem?
      @sbItem = document.createElement 'div'
      @sbItem.classList.add 'inline-block'
      @sbItem.classList.add 'mode-insert'
      @sbItem.textContent = 'INS'
      @sbItem.addEventListener 'click', => @toggle()
      @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'
    
    @sbTile.destroy() if @sbTile?
    
    @log "setupIndicator cfg = '#{@cfg 'Package.showIndicator'}'", 1
    
    switch @cfg 'Package.showIndicator'
      
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
    #
    # package-deactivation & clean-up
    #
    @log "deactivate:: starts", 1
    
    @disable()
    @events.dispose()
    @cmds.dispose()

    @sbTile?.destroy()
    @sbItem = null if @sbItem?
    #
    # look into any TextEditor-instance we hooked into.
    # @enabledEd is a set of TextEditor.ids, that have
    # the overtype-mode enabled.
    # 
    # 'pristine_' is the prefix for atoms genuine-fn.
    # rolling everything back, hopefully.
    # NOTE look into this, maybe use a WeakRef smth. leaks.
    # look at any running instance.
    #
    atom.workspace.getTextEditors().map (editor) ->
      if editor.pristine_insertNewline?
        editor.enter = editor.pristine_insertNewline
        editor.pristine_insertNewline = null
    
    @enabledEd.clear()
    
    @log "deactivate:: ends", 1


  toggle: ->
    # 
    # mode activation happens here.
    # 
    return unless editor = @activeEditor()
    
    @log "toggle:: starts editor.id #{editor.id}", 1
    
    if @active editor
      #
      # from enabled to disabled.
      #
      @enabledEd.delete editor.id
      @disable()
    else
      #
      # from disabled to enabled.
      #
      @enabledEd.add editor.id
      @enable()

    @updateCursorStyles() if @cfg 'Package.changeCaretStyle'
    
    @log "toggle:: editoren=#{@enabledEd.size} ids=#{Array.from @enabledEd}", 1


  enable: ->
    # 
    # visual feedback via CSS-classes for
    # - cursor-styling and
    # - the status-bar-indicator
    #
    @log "enable:: starts"
    
    return if 'no' == @cfg 'Package.showIndicator'
  
    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Overwrite'
    @sbItem.textContent = 'DEL'
    @sbItem.classList.remove 'hide-indictator' if @hidden
    @sbItem.classList.remove 'mode-insert'
    @sbItem.classList.add    'mode-overwrite'
    
    @log "enable:: ends"

   
  disable: ->
    @log "disable:: starts"
    
    return if 'no' == @cfg 'Package.showIndicator'

    @sbTooltip = atom.tooltips.add @sbItem, title: 'Mode: Insert'
    @sbItem.textContent = 'INS'
    @sbItem.classList.remove 'hide-indictator' if @hidden
    @sbItem.classList.remove 'mode-overwrite'
    @sbItem.classList.add    'mode-insert'
    
    @log "disable:: ends"

    
  updateCursorStyle: (editor) ->
    
    view = atom.views.getView editor
    if @active editor
      view.classList.add @caretClass
    else
      view.classList.remove @caretClass


  updateCursorStyles: ->
    return unless @cfg 'Package.changeCaretStyle'
    
    for editor in atom.workspace.getTextEditors()
      @updateCursorStyle editor


  prepareEditor: (editor) ->
    # 
    # hook from atom.workspace.observeEditors lands here.
    # prepares any TextEditor upon creation :
    #
    # TODO Is there a better way to hook into such KB-events ?
    #
    # - hooks into .insertNewline to intercept ENTER/RETURN
    #
    #
    @log "prepareEditor:: starts editor.id='#{editor.id}'"
    
    if @cfg 'Keypress.keyReturn'
    
      unless editor.pristine_insertNewline?
        editor.pristine_insertNewline = editor.insertNewline
        editor.insertNewline = => @enter()
    
    #
    # observes Selections upon creation in order to
    # detect insertions from the autocomplete-plus-pkg.
    #
    editor.observeSelections (sel) =>
      
      unless sel.pristine_insertText?
        sel.pristine_insertText = sel.insertText
        
      isAutocompleteInsert = (sel, txt) =>
        #
        # HACK need to find a event or hook from autocomplete-plus!
        #
        # it seems to be a autocomplete-insert if, 
        #
        # - the term-length is at least @minComplete which comes from 
        #   the autocomplete-plus-settings. defaults to three.
        # - when the text-part to become inserted, starts with the
        #   current selection. Then chances are good, its a auto-
        #   completion or a snippet. Very fuzzy terms will most 
        #   likely fail and pass by undetected. 
        #   The 'strict-matching'-setting can improve the hit-rate #   here.
        # 
        minLen = @minComplete
        selTxt = sel.getText()
        selLen = selTxt.length
        txtLen = txt.length
        
        r = (minLen <= selLen <= txtLen ) and ( txt.startsWith selTxt )
        @log "isAutocompleteInsert:: returns '#{r}'", 2
        r


      fitsCurrentLine = (sel, selLen, txtLen) ->
        #
        # tests if the text to be inserted fits on the current
        # buffer-line.
        
        { start } = sel.getBufferRange()
        lineLen   = sel.editor.lineTextForBufferRow(start.row).length
        
        ( lineLen - start.column + selLen - txtLen ) > 0
        
        
      sel.insertText = ( txt, opts ) =>
        #
        # HACK against the notorious 'AtomicSoftTabs'
        #
        # ast = atom.config.get 'editor.atomicSoftTabs'
        # if ast
        #   atom.config.set 'editor.atomicSoftTabs', off
        # 
        # fixAst = ->
        #   atom.config.set 'editor.atomicSoftTabs', ast
        #
        # FIXME ugly
        #
        
        
        @log "Selection.insertText has txt='#{txt}'", 1
        
        unless @active()
          #
          # standard-mode-action for 'selection.insertText'
          #
          return sel.pristine_insertText txt, opts

        else unless @cfg 'enableAutocomplete'
          @log ".insertText autocomplete-support is off."
          return sel.pristine_insertText txt, opts

        unless isAutocompleteInsert sel, txt
          return sel.pristine_insertText txt, opts
            
        @log ".insertText autocomplete ? txt='#{txt}'", 1
        
        editor = sel.editor
        selLen = sel.getText().length
        txtLen = txt.length
        prefix = sel.getText()

        editor.mutateSelectedText (sel, idx) =>
          # log "sel-#{idx} '#{sel.getText()}'"
          range = sel.getBufferRange()
          
          if sel.isEmpty()
            range.start.column -= prefix.length
            
          p2 = sel.editor.getTextInBufferRange range
          # log "p2='#{p2}' == '#{prefix}'", p2 == prefix
          return if p2 isnt prefix
          
          @log ".insertText autocomplete on prefix='#{prefix}' txt='#{txt}'", 1
          
          if fitsCurrentLine sel, selLen, txtLen
            # fits on one buffer-line
            range.end.column += txtLen - p2.length
            res = editor.setTextInBufferRange range, txt
          else
            # no, buffer-line needs expansion.
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
          @log ".insertText done range.end '#{res.end}'", 1
          
          res

    
    @updateCursorStyles()
    
    @events.add(
      #
      # This hooks into the TextEditor-instance
      # and handles most regular single-char-key-strokes.
      #
      editor.onWillInsertText @onType
    )


  # info: (editor) ->
  #   log = console.log
  #   log "multiple cursors", editor.hasMultipleCursors()
  #   selectedText = editor.getSelectedText()
  #   sels = editor.getSelections()
  #   log "has #{sels.length}-selection-len=#{selectedText.length} '#{selectedText}'"
  #   for sel, i in sels
  #     log "\tsel-#{i}", sel.getScreenRange()


  onType: ( evt ) =>
    #
    return unless editor = @active()
    #
    # only trigger when user types manually.
    #
    wEvent = window.event
    @log "onType window-event '#{wEvent}'"
    
    # if wEvent instanceof CustomEvent
    #   if wEvent.originalEvent instanceof KeyboardEvent
    #     evt = wEvent.originalEvent
    # 
    #     switch evt.code
    #       when 'NumpadEnter'
    #         wEvent.stopImmediatePropagation()
    #         wEvent.preventDefault()
    #         wEvent.stopPropagation()
    #         console.log "enter detected & canceled..."
    
    return unless wEvent instanceof TextEvent
   
    #atom.config.set 'editor.atomicSoftTabs', off
    @log "onType editor.id '#{editor.id}'"
    
    for sel in editor.getSelections()
      
      if sel.isEmpty() 
        continue if sel.cursor.isAtEndOfLine()
      
      unless @cfg 'Others.bracketMatcher.singleCharFilter'
        sel.selectRight()
        continue 
        
      if evt.text.length == 2
        #
        # HACK better solution welcome !?!
        # 2-char-long events come 
        # typically from the bracket-matcher-pkg
        # As a quick&dirty solution, we
        # use only the first-char..
        #
        evt.cancel()
        theChar = evt.text[0]
        sel.insertText theChar
        sel.cursor.moveRight()
        
        @log "onType 2-char-event '#{theChar}'"

    #atom.config.set 'editor.atomicSoftTabs', on
#
# inject the implementations of behaviours.
#
# TODO make this smarter and check if a cmd/action has been 
# actually been enabled thru user & settings.
#
for cmd, action of actions
  OvertypeMode::[cmd] = action

module.exports = new OvertypeMode
