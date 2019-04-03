module.exports =

startMode:
  order: 5
  title: 'Set the default mode.'
  description: 'The **insert**-mode is the normal input-mode. Set this to **overwrite** if you want to startup in **overwrite**-mode.'
  type: 'string'
  default: 'insert'
  enum: ['insert', 'overwrite']
showIndicator:
  order: 6
  title: 'Show the mode-indicator inside the status-bar.'
  description: 'Display the mode-indicator either on the **left**- or **right**-side of the status-bar. Choose **no** to hide the indicator.'
  type: 'string'
  default: 'right'
  enum: ['left', 'right', 'no']
changedDelete:
  order: 7
  title: 'Changes the behaviour of the delete-key.'
  description: 'In **overwrite**-mode a keypress replaces the character under the caret with a space-char. Not changing the line-length. When the caret is at the very end of a line, then nothing happens.'
  type: 'boolean'
  default: on
changedBackspace:
  order: 8
  title: 'Changes the behaviour of the backspace-key.'
  description: 'In **overwrite**-mode a keypress replaces the character left from the caret with a space-char. Not changing the line-length. When the caret is positioned at the very beginning of a line, then nothing happens.'
  type: 'boolean'
  default: on
usePasteOver:
  order: 10
  title: 'Use destructive-insert behaviour for clipboard-paste operations.'
  description: 'When enabled, any common paste-operation (Ctrl-v, Cmd-v) in **overwrite**-mode performs a *destructive*-insert starting from the current caret-position to the right. The contents of the clip-board **overwrite the existing contents**.'
  type: 'boolean'
  default: on
changeCaretStyle:
  order: 20
  title: 'Changes the display-style of the caret.'
  description: 'Since i use the *simple-block-cursor*-pkg, i use this setting to deactivate any changes to the caret from this package.'
  type: 'boolean'
  default: off
