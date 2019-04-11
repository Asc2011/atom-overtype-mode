log = console.log 

cmd = {}

overwriteSelection = ( sel, caretPos='start', keepSelection=yes ) ->
  
  text   = sel.getText()
  space  = ' '.repeat text.length
  range  = sel.getBufferRange()
  sel.insertText space
  #
  # keep the selection, but place the caret
  # at the beginning or end.
  #
  sel.setBufferRange { 
    start : range[ caretPos ]
    end   : range[ caretPos ]
  }
  sel.clear() unless keepSelection


cmd.duplicateLines = ->

  unless editor = @active()
    #
    # standard-mode for 'editor:newline-below'
    #
    return @activeEditor().insertNewlineBelow()

  editor.duplicateLines()


cmd.pasteLikeLawrence = ->
  console.info "pasteLikeLawrence:: starts"
  
  clipboardText = atom.clipboard.read()
  return if clipboardText.length is 0

  lineEnding = @getLineEnding()
  lines = clipboardText.split lineEnding
  
  if lines.length is 1
    console.info "no content or single-line to paste. returning"
    return
    
  editor = @activeEditor()
  #
  # on what column are we ?
  #
  { row, column } = editor.getCursorBufferPosition()
  
  if column is 0
    #
    # caret position is at beginning-of-line.
    # nothing to add to the clipboard-text.
    #
    newLines = lines
  else
    #
    # copy the line-beginnings.
    #
    newLines = []
    for newLine, idx in lines
      oldLine = editor.lineTextForBufferRow row + idx
      
      leftPrefix = oldLine[ ...column ]
      if leftPrefix.length < column 
        spc = ' '.repeat column - leftPrefix.length
        leftPrefix += spc
        
      newLines.push leftPrefix + newLine
  
  try
    #
    # save current buffer-state.
    #
    pristineBuffer = editor.createCheckpoint()
    
    lastLineIdx = row + newLines.length - 1
    lastLine = editor.lineTextForBufferRow lastLineIdx
    #
    # define the region to overwrite.
    #
    targetRange = [ 
      [ row, 0 ],
      [ lastLineIdx, lastLine.length ]
    ]
    #
    # replace the contents of the overwrite-region.
    #
    { end } = editor.setTextInBufferRange(
      targetRange,
      newLines.join lineEnding
    )
    editor.setCursorBufferPosition end
    #
    # merge change into a single 'undo'-operation.
    #
    editor.groupChangesSinceCheckpoint pristineBuffer
    console.info 'pasteLikeLawrence:: finished without error.'
    #
  catch error
    #
    # smth went wrong ?
    console.error "pasteLikeLawrence:: error was", error
    #
    # revert all changes to the buffer.
    #
    editor.revertToCheckpoint pristineBuffer


cmd.backspace2col0 = ->
  #
  # TODO add a setting for this.
  #
  unless (editor = @active()) # or (off is @cfg 'changedBackspace2Col0')
    #
    # standard-mode for 'editor:delete-to-beginning-of-line'
    #
    return @activeEditor().deleteToBeginningOfLine()
    
  try
    pristineBuffer = editor.createCheckpoint()
    
    { row, column } = editor.getCursorBufferPosition()
    newRange = [ [row, 0], [row, column] ]
    newText = ' '.repeat column
    editor.setTextInBufferRange newRange, newText
    editor.setCursorBufferPosition [row, 0]
    editor.groupChangesSinceCheckpoint pristineBuffer
    
  catch error
    console.error 'backspace2col0:: had error:', error
    editor.revertToCheckpoint pristineBuffer


cmd.backspace2lastcol = ->
  
  # TODO add a setting for this.
  unless editor = @active() 
    # or (off is @cfg 'changedBackspace2Col0')
    #
    # standard-mode for 'editor:delete-to-end-of-line'
    #
    return @activeEditor().deleteToEndOfLine()

  console.log "backspace2lastcol::start"
  try
    pristineBuffer = editor.createCheckpoint()
    
    { row, column } = editor.getCursorBufferPosition()
    
    lineLen = editor.lineTextForBufferRow( row ).length
    newRange = [
      [ row, column ],
      [ row, lineLen ]
    ]
    newText = ' '.repeat lineLen-column
    editor.setTextInBufferRange newRange, newText
  
  catch error
    console.error "backspace2lastcol:: had error:", error
    editor.revertToCheckpoint pristineBuffer


cmd.enter = ->
  #
  # This implementation performs a carriage-return to the 
  # first character of the line below the current line.
  # It won't insert a line-feed, before the cursor is 
  # on the last line of the buffer. Then a new-line gets 
  # inserted.
  #
  unless (editor = @active()) or (off is @cfg 'changedReturn')
    #
    # standard-mode for enter 'core:insertNewline'
    #
    return @activeEditor().pristine_insertNewline()
  
  cursor    = editor.getLastCursor()
  lastRow   = editor.getLastBufferRow()
  cursorPos = cursor.getBufferPosition()
  
  if cursorPos.row == lastRow
    # 
    # insert new-line only at the end of the document.
    #
    cursor.moveToEndOfLine()
    editor.pristine_insertNewline()
  else
    #
    # jump to the first char of next line.
    #
    cursor.moveDown()
    cursor.moveToFirstCharacterOfLine()


cmd.backspace = ->
  #
  # This implements a backspace in the literal
  # sense of the word: it moves the curser one step
  # back (LTR=to the left) and replaces the character on
  # that spot with a space. It does not however replace 
  # line-endings (return-char) or space-chars.
  # Instead it moves over, until it finds a character.
  #
  
  unless ( editor = @active() ) or (off is @cfg 'changedBackspace')
    #
    # standard-mode for backspace 'core:backspace'
    #
    return @activeEditor().backspace()
  
  editor.mutateSelectedText ( sel, idx ) ->
    
    if sel.isEmpty()
      cursor = sel.cursor
      
      while cursor.isAtBeginningOfLine()
        cursor.moveLeft()
      
      sel.selectLeft()
      sel.insertText ' '
      cursor.moveLeft()
      
    else overwriteSelection sel


cmd.delete = ->
  #
  # This behaviour overwrites the char under the caret with
  # a space-char, but only if it is a character.
  # It does nothing on line-endings. 
  # In case of a space-char, it will perform the standard 
  # delete-operation. Thus pull the text on the right side of
  # the caret one step to the left.
  # Basically the first hit of the delete-key overwrites with a space.
  # A second hit will delete the space-char.
  #
  unless (editor = @active()) or (off is @cfg 'changedDelete')
    #
    # standard-mode for delete 'core:delete'
    #
    return @activeEditor().delete()
  
  editor.mutateSelectedText ( sel, idx ) ->
    
    unless sel.isEmpty()
      #
      # there is selected-text.
      #
      return overwriteSelection sel
    #
    # no text selected.
    #
    cur  = sel.cursor
    col  = cur.getBufferColumn()
    char = cur.getCurrentBufferLine()[col]
    #
    sel.delete()
    #
    unless editor.hasMultipleCursors()
      #
      # only in single-cursor-mode,
      # test for space under cursor 
      #
      return if char is ' '
    #
    # always overwrite in multi-caret-mode.
    #
    range = sel.getBufferRange()
    editor.setTextInBufferRange range, ' '
    sel.cursor.moveLeft()


cmd.paste = ->

  unless (editor = @active()) or (off is @cfg 'changedPaste')
    #
    # standard-mode for paste 'core:pasteText'
    #
    return @activeEditor().pasteText()

  clipboardText = atom.clipboard.read()
  single = clipboardText.includes '\n'
  return if clipboardText.length is 0
  
  cursor = editor.getLastCursor()
  rc_pos = cursor.getScreenPosition()
  editor.selectRight clipboardText.length
  editor.insertText clipboardText
  log "it paste stupid"
  cursor.setScreenPosition rc_pos


cmd.smartInsert = ->
  #
  # This mode tries to make use of 'spaced'-areas on the 
  # current line. A spaced-area comprises of at least two 
  # or more consecutive space-chars.
  #
  getIndent = ( line ) ->
    try
      [ spaces ] = /^ +/.exec line
      return spaces.length
    0


  hasSpacedArea = ( line, start=0 ) ->
    
    indent = getIndent line
    areas = [ [indent, line.length, line] ]
    
    start = indent if (start < indent)
    end = line.length
    
    c = 0
    until start == end
      #log "until has start=#{start}"
      char = line[start]
      log "start=#{start} char='#{char}' c=#{c}"
      break unless char?
      
      if char is ' '
        c++
      else
        if c > 1
          areas.push { s: start-c, e: start, b: char }
        c = 0
      
      start++
      
    log "ends with start=#{start}"
    areas

  
  hasStructure = ( editor, bufferRow ) ->
    
    isChar  = (char) -> /[a-zA-Z@]/.test char
    isDelim = (char) -> /[\(\)"'\{\}\[\]+-]/.test char
    
    similar = ( row1, row2) ->
      l1 = row1[..]; l2 = row2[..] 
      [ l1Indent, l1Len, line1 ] = l1.shift()
      [ l2Indent, l2Len, line2 ] = l2.shift()

      return no unless l1Indent is l2Indent
      
      truth = no
      unless l1.length
        [l1, l2] = [l2, l1] if l2.length > 0
        
      for area, i in l1
        { s:s1, e:e1, b:b1 } = area
        unless l2[i]?
          # log "boundary-cmp '#{b1}' '#{line2[e1]}'", e1
          return yes if ( b1 is line2[e1] )
        else
          { s:s2, e:e2, b:b2 } = l2[i]
          continue if e1 isnt e2
          return no if b1 isnt b2
          truth = yes if (b1 is b2) and (e1 is e2)
        
      #log "similar:: returns", truth
      truth


    truth = []
    line = editor.lineTextForBufferRow bufferRow
    a1 = hasSpacedArea line 
    above = editor.lineTextForBufferRow bufferRow - 1
    a2 = hasSpacedArea above
    log line
    log above
    log "------"
    log a1
    log a2
    truth.push similar a1, a2
    
    below = editor.lineTextForBufferRow bufferRow + 1
    a3 = hasSpacedArea below
    truth.push similar a1, a3
    truth
  
  editor = @activeEditor()
  { row, column } = editor.getCursorBufferPosition()
  
  console.log hasStructure editor, row

  return
  
  sim = (l1, l2) ->
    l1 = l1.split ''
    l2 = l2.split ''
    len = Math.min l1.length, l2.length
    
    console.log "length is ", len
    
    r = new Array(len).fill false
     
    r.map (e, idx) ->
      
      return unless l1[idx] is ' '
      
      if l1[idx] == l2[idx]
        r[idx] = l1[idx]
    
    console.log "result is r::", r
    r
    
  editor = @activeEditor()
  cursor = editor.getLastCursor()
  
  [ scope ] = editor.getRootScopeDescriptor().scopes 
  console.log "scope is", scope
  
  nonWord = atom.config.get 'editor.nonWordCharacters'
  console.log "non-word ", nonWord
  { row, column } = editor.getCursorScreenPosition()
  
  # indent = cursor.getIndentLevel()
  # console.log "indent is", indent
  
  t0 = editor.lineTextForBufferRow row
  t1 = editor.lineTextForBufferRow row+1
    
  console.log "indent is", ind(t0)
  
  sim t0, t1


cmd._paste = ->
  
  cursor = editor.getLastCursor()

  unless @active()
    #
    # standard-mode for paste 'core:pasteText'
    #
    return @activeEditor().pasteText()
  
  return unless @cfg 'changedPaste'
  
  clipboardText = atom.clipboard.read()
  return if clipboardText.length is 0
  
  single = clipboardText.includes '\n'
  cursor = editor.getLastCursor()
  
  editor.selectRight clipboardText.length


module.exports = cmd
