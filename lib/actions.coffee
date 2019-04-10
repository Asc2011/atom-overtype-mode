###

  Ihis file contains the implementations of actions taken
  on a particular keypress.
 
###

cmd = {}

cmd.pasteLikeLawrence = ->
  console.info "pasteLikeLawrence:: starts"
  
  clipboardText = atom.clipboard.read()
  return if clipboardText.length is 0
  
  # TODO how can i get the line-ending in-use from atom ?
  #
  # general-purpose-text-splitter
  #
  lineEnding = @getLineEnding()
  lines = clipboardText.split lineEnding
  
  if lines.length is 1
    console.info "no content or single-line to paste. returning"
    return
    
  # editor = atom.workspace.getActiveTextEditor()
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
    # save the buffer-state.
    #
    pristineBuffer = editor.createCheckpoint()
    
    lastLineIdx = row + newLines.length - 1
    lastLine = editor.lineTextForBufferRow lastLineIdx
    
    # define the region to overwrite.
    #
    range = [ 
      [ row, 0 ],
      [ lastLineIdx, lastLine.length ]
    ]
    # replace the contents of the overwrite-region.
    #
    # FIXME need the line-ending to use here ?
    #
    { end } = editor.setTextInBufferRange(
      range, 
      newLines.join lineEnding
    )
    editor.setCursorBufferPosition end
    #
    # merge all changes into a single 'undo'-operation.
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
    
  console.info "backspace2col0::start"
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
  
  cursor = editor.getLastCursor()
  if cursor.isAtBeginningOfLine()

    while not cursor.hasPrecedingCharactersOnLine()
      cursor.moveLeft()
      { column, row } = cursor.getBufferPosition()
      break if row == 0
    
  editor.selectLeft()
  editor.mutateSelectedText (sel, idx) ->
    sel.insertText ' ', select: yes
    sel.clear()


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

  #
  # cycle thru all selections
  #
  for sel in editor.getSelections()
    
    txt = sel.getText()
    cursor = editor.getLastCursor()
    
    if txt.length > 1
      #
      # prepare replacement-spaces
      #
      spaces = ' '.repeat txt.length
      range = sel.getScreenRange()
      sel.insertText spaces
      #
      # place the caret to the beginning
      # of the replacement-region.
      #
      cursor.setScreenPosition [
        range.start.row
        range.start.column
      ]
    else
      line = cursor.getCurrentBufferLine()
      char = line[ cursor.getBufferColumn() ]
      #
      # char is the char under the caret.
      # its <undefined> for line-feeds / '\n'.
      #
      return unless char
      
      editor.delete()
      
      unless char is ' '
        #
        # special-case: space under the caret.
        #
        editor.insertText ' '
        editor.moveLeft()


cmd.paste = ->

  console.log "in paste"

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
  cursor.setScreenPosition rc_pos


cmd.smartInsert = ->
  
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


ind = ( line ) ->
  [ indent ] = /^ */.exec line
  indent.length


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
