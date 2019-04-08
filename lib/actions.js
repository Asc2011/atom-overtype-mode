
/*

  Ihis file contains the implementations of actions taken
  on a particular keypress.
 */
var cmd, ind;

cmd = {};

cmd.enter = function() {
  var cursor, cursorPos, editor, lastRow;
  if (!((editor = this.active()) || (false === this.cfg('changedReturn')))) {
    return this.activeEditor().pristine_insertNewline();
  }
  cursor = editor.getLastCursor();
  lastRow = editor.getLastBufferRow();
  cursorPos = cursor.getBufferPosition();
  if (cursorPos.row === lastRow) {
    cursor.moveToEndOfLine();
    return editor.pristine_insertNewline();
  } else {
    cursor.moveDown();
    return cursor.moveToFirstCharacterOfLine();
  }
};

cmd.backspace = function() {
  var column, cursor, editor, ref, row;
  if (!((editor = this.active()) || (false === this.cfg('changedBackspace')))) {
    return this.activeEditor().backspace();
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

cmd["delete"] = function() {
  var char, cursor, editor, i, len1, line, range, ref, sel, spaces, txt;
  if (!((editor = this.active()) || (false === this.cfg('changedDelete')))) {
    return this.activeEditor()["delete"]();
  }
  ref = editor.getSelections();
  for (i = 0, len1 = ref.length; i < len1; i++) {
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
};

cmd.paste = function() {
  var clipboardText, cursor, editor, rc_pos, single;
  console.log("in paste");
  if (!((editor = this.active()) || (false === this.cfg('changedPaste')))) {
    return this.activeEditor().pasteText();
  }
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
};

cmd.smartInsert = function() {
  var column, cursor, editor, nonWord, ref, row, scope, sim, t0, t1;
  sim = function(l1, l2) {
    var len, r;
    l1 = l1.split('');
    l2 = l2.split('');
    len = Math.min(l1.length, l2.length);
    console.log("length is ", len);
    r = new Array(len).fill(false);
    r.map(function(e, idx) {
      if (l1[idx] !== ' ') {
        return;
      }
      if (l1[idx] === l2[idx]) {
        return r[idx] = l1[idx];
      }
    });
    console.log("result is r::", r);
    return r;
  };
  editor = this.activeEditor();
  cursor = editor.getLastCursor();
  scope = editor.getRootScopeDescriptor().scopes[0];
  console.log("scope is", scope);
  nonWord = atom.config.get('editor.nonWordCharacters');
  console.log("non-word ", nonWord);
  ref = editor.getCursorScreenPosition(), row = ref.row, column = ref.column;
  t0 = editor.lineTextForBufferRow(row);
  t1 = editor.lineTextForBufferRow(row + 1);
  console.log("indent is", ind(t0));
  return sim(t0, t1);
};

ind = function(line) {
  var indent;
  indent = /^ */.exec(line)[0];
  return indent.length;
};

cmd._paste = function() {
  var clipboardText, cursor, single;
  cursor = editor.getLastCursor();
  if (!this.active()) {
    return this.activeEditor().pasteText();
  }
  if (!this.cfg('changedPaste')) {
    return;
  }
  clipboardText = atom.clipboard.read();
  if (clipboardText.length === 0) {
    return;
  }
  single = clipboardText.includes('\n');
  cursor = editor.getLastCursor();
  return editor.selectRight(clipboardText.length);
};

module.exports = cmd;
