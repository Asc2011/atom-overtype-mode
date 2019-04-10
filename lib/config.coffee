module.exports =

startMode:
  
  title: 'Sets the default mode.'
  description: 'The **insert**-mode is the normal input-mode. Set this to **overwrite** if you want to startup in **overwrite**-mode.'
  order   : 2
  type    : 'string'
  default : 'insert'
  enum    : [ 'insert', 'overwrite' ]
  
showIndicator:
  title: 'Display a mode-indicator inside the status-bar.'
  description: """
    Display a mode-indicator either on the **left**- or **right**-side of the status-bar. Choose **no** to hide the indicator entirely."""
  order   : 3
  type    : 'string'
  default : 'right'
  enum    : [ 'left', 'right', 'no' ]
  
enableAutocomplete:
  title: 'Inserts via autocomplete shall overwrite.'
  description: """
    When enabled a **autocomplete-insert** overtypes into the buffer-line. If the remaining space on the current line does not  suffice, then a insert is done."""
  order   : 6
  type    : 'boolean'
  default : on
  
changedDelete:
  title: 'Changed behaviour of the delete-key.'
  description: """
    In **overwrite**-mode a keypress replaces the character under the caret with a space-char. Not changing the line-length. When the caret is at the very end of a line, then nothing happens."""
  order   : 7
  type    : 'boolean'
  default : on
  
changedBackspace:
  title: 'Changed behaviour of the backspace-key.'
  description: """
    In **overwrite**-mode a keypress replaces the character left from the caret with a space-char. Not changing the line-length. When the caret is positioned at the very beginning of a line, then nothing happens."""
  order   : 8
  type    : 'boolean'
  default : on
  
changedPaste:
  title: 'Use destructive-insert behaviour for clipboard-paste operations.'
  description: """
    When enabled, any common paste-operation (Ctrl-v, Cmd-v) in **overwrite**-mode performs a *destructive*-insert starting from the current caret-position to the right. The contents of the clip-board **overwrite the existing contents**."""
  order   : 10
  type    : 'boolean'
  default : on
  
changedReturn:
  title: 'Changed behaviour of the return-key.'
  description: """
    When enabled, a RETURN-key pressed does not insert a new-line. Instead the caret moves to the beginning of the next line."""
  order   : 11
  type    : 'boolean'
  default : on
  
changeCaretStyle:
  title: 'Changes the display-style of the caret.'
  description: """
    Since i use the *simple-block-cursor*-pkg, one can use this setting to deactivate any changes to the caret-style from this package."""
  order   : 20
  type    : 'boolean'
  default : on
