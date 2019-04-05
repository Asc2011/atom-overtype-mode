
/*

  Ihis file contains the implementations of actions taken
  on a particular keypress.
 */
var key;

key = {};

key.enter = function() {
  var cursor, editor;
  editor = this.activeEditor();
  if (!this.active) {
    return editor._insertNewline();
  }
  if (this.cfg('changedReturn')) {
    cursor = editor.getLastCursor();
    cursor.moveDown();
    return cursor.moveToFirstCharacterOfLine();
  }
};

key.backspace = function() {
  var column, cursor, editor, ref, row;
  editor = this.activeEditor();
  if (!this.active) {
    return editor.backspace();
  } else if (!this.cfg('changedBackspace')) {
    editor.backspace();
  }
  cursor = editor.getLastCursor();
  if (cursor.isAtBeginningOfLine()) {
    while (!cursor.hasPrecedingCharactersOnLine()) {
      cursor.moveLeft();
      ref = cursor.getBufferPosition(), column = ref.column, row = ref.row;
      if (row === 0) {
        break;
      }
    }
  }
  editor.selectLeft();
  return editor.mutateSelectedText(function(sel, idx) {
    sel.insertText(' ', {
      select: true
    });
    return sel.clear();
  });
};

key["delete"] = function() {
  var char, cursor, editor, i, len, line, range, ref, sel, spaces, txt;
  editor = this.activeEditor();
  if (!this.active) {
    return editor["delete"]();
  }
  if (this.cfg('changedDelete')) {
    ref = editor.getSelections();
    for (i = 0, len = ref.length; i < len; i++) {
      sel = ref[i];
      txt = sel.getText();
      cursor = editor.getLastCursor();
      if (txt.length > 1) {
        spaces = ' '.repeat(txt.length);
        range = sel.getScreenRange();
        sel.insertText(spaces);
        cursor.setScreenPosition([range.start.row, range.start.column]);
      } else {
        line = cursor.getCurrentBufferLine();
        char = line[cursor.getBufferColumn()];
        if (!char) {
          return;
        }
        editor["delete"]();
        if (char !== ' ') {
          editor.insertText(' ');
          editor.moveLeft();
        }
      }
    }
  }
};

key.paste = function() {
  var clipboardText, cursor, editor, rc_pos, single;
  editor = this.activeEditor();
  if (!this.active) {
    return editor.pasteText();
  }
  if (this.cfg('changedPaste')) {
    clipboardText = atom.clipboard.read();
    single = clipboardText.includes('\n');
    if (clipboardText.length === 0) {
      return;
    }
    cursor = editor.getLastCursor();
    rc_pos = cursor.getScreenPosition();
    editor.selectRight(clipboardText.length);
    editor.insertText(clipboardText);
    return cursor.setScreenPosition(rc_pos);
  }
};

module.exports = key;
