###

  Ihis file contains the implementations of actions taken
  on a particular keypress.
 
###

key = {}

key.enter = ->
  #
  # This implementation does a carriage-return to the 
  # first character of the line below the current line.
  # It won't insert a line-feed.
  #
  editor = @activeEditor()

  unless @active
    #
    # standard-mode for enter 'core:insertNewlinee'
    #
    return editor._insertNewline()

  if @cfg 'changedReturn'
    
    cursor = editor.getLastCursor()
    cursor.moveDown()
    cursor.moveToFirstCharacterOfLine()


key.backspace = ->
  #
  # This implements a backspace in the literal
  # sense of the word: it moves the curser one step
  # back (LTR=to the left) and replaces the character on
  # that spot with a space. It does not however replace 
  # line-endings (return-char) or space-chars.
  # Instead it moves over, until it finds a character.
  #
  editor = @activeEditor()

  unless @active then return editor.backspace()
  else unless @cfg 'changedBackspace'
    editor.backspace()

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


key.delete = ->
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
  editor = @activeEditor()
  
  unless @active
    #
    # standard-mode for delete 'core:delete'
    #
    return editor.delete()
    
  if @cfg 'changedDelete'
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
        
        # char is the char under the caret.
        # its <undefined> for line-feeds / '\n'.
        #
        return unless char
        
        editor.delete()
        #
        # special-case: space under the caret.
        #
        unless char is ' '
          editor.insertText ' '
          editor.moveLeft()


key.paste = ->
    
  editor = @activeEditor()

  unless @active
    #
    # standard-mode for paste 'core:pasteText'
    #
    return editor.pasteText()
  
  if @cfg 'changedPaste'
    clipboardText = atom.clipboard.read()
    single = clipboardText.includes '\n'
    return if clipboardText.length is 0
      
    cursor = editor.getLastCursor()
    rc_pos = cursor.getScreenPosition()
    editor.selectRight clipboardText.length
    editor.insertText clipboardText
    cursor.setScreenPosition rc_pos

module.exports = key
