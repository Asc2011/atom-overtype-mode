var cmd, log, overwriteSelection;

log = console.log;

cmd = {};

overwriteSelection = function(sel, caretPos, keepSelection) {
  var range, space, text;
  if (caretPos == null) {
    caretPos = 'start';
  }
  if (keepSelection == null) {
    keepSelection = true;
  }
  text = sel.getText();
  space = ' '.repeat(text.length);
  range = sel.getBufferRange();
  sel.insertText(space);
  sel.setBufferRange({
    start: range[caretPos],
    end: range[caretPos]
  });
  if (!keepSelection) {
    return sel.clear();
  }
};

cmd.duplicateLines = function() {
  var editor;
  if (!(editor = this.active())) {
    return this.activeEditor().insertNewlineBelow();
  }
  return editor.duplicateLines();
};

cmd.pasteLikeLawrence = function() {
  var clipboardText, column, editor, end, error, idx, j, lastLine, lastLineIdx, leftPrefix, len1, lineEnding, lines, newLine, newLines, oldLine, pristineBuffer, ref, row, spc, targetRange;
  console.info("pasteLikeLawrence:: starts");
  clipboardText = atom.clipboard.read();
  if (clipboardText.length === 0) {
    return;
  }
  lineEnding = this.getLineEnding();
  lines = clipboardText.split(lineEnding);
  if (lines.length === 1) {
    console.info("no content or single-line to paste. returning");
    return;
  }
  editor = this.activeEditor();
  ref = editor.getCursorBufferPosition(), row = ref.row, column = ref.column;
  if (column === 0) {
    newLines = lines;
  } else {
    newLines = [];
    for (idx = j = 0, len1 = lines.length; j < len1; idx = ++j) {
      newLine = lines[idx];
      oldLine = editor.lineTextForBufferRow(row + idx);
      leftPrefix = oldLine.slice(0, column);
      if (leftPrefix.length < column) {
        spc = ' '.repeat(column - leftPrefix.length);
        leftPrefix += spc;
      }
      newLines.push(leftPrefix + newLine);
    }
  }
  try {
    pristineBuffer = editor.createCheckpoint();
    lastLineIdx = row + newLines.length - 1;
    lastLine = editor.lineTextForBufferRow(lastLineIdx);
    targetRange = [[row, 0], [lastLineIdx, lastLine.length]];
    end = editor.setTextInBufferRange(targetRange, newLines.join(lineEnding)).end;
    editor.setCursorBufferPosition(end);
    editor.groupChangesSinceCheckpoint(pristineBuffer);
    return console.info('pasteLikeLawrence:: finished without error.');
  } catch (error1) {
    error = error1;
    console.error("pasteLikeLawrence:: error was", error);
    return editor.revertToCheckpoint(pristineBuffer);
  }
};

cmd.backspace2col0 = function() {
  var column, editor, error, newRange, newText, pristineBuffer, ref, row;
  if (!(editor = this.active())) {
    return this.activeEditor().deleteToBeginningOfLine();
  }
  try {
    pristineBuffer = editor.createCheckpoint();
    ref = editor.getCursorBufferPosition(), row = ref.row, column = ref.column;
    newRange = [[row, 0], [row, column]];
    newText = ' '.repeat(column);
    editor.setTextInBufferRange(newRange, newText);
    editor.setCursorBufferPosition([row, 0]);
    return editor.groupChangesSinceCheckpoint(pristineBuffer);
  } catch (error1) {
    error = error1;
    console.error('backspace2col0:: had error:', error);
    return editor.revertToCheckpoint(pristineBuffer);
  }
};

cmd.backspace2lastcol = function() {
  var column, editor, error, lineLen, newRange, newText, pristineBuffer, ref, row;
  if (!(editor = this.active())) {
    return this.activeEditor().deleteToEndOfLine();
  }
  console.log("backspace2lastcol::start");
  try {
    pristineBuffer = editor.createCheckpoint();
    ref = editor.getCursorBufferPosition(), row = ref.row, column = ref.column;
    lineLen = editor.lineTextForBufferRow(row).length;
    newRange = [[row, column], [row, lineLen]];
    newText = ' '.repeat(lineLen - column);
    return editor.setTextInBufferRange(newRange, newText);
  } catch (error1) {
    error = error1;
    console.error("backspace2lastcol:: had error:", error);
    return editor.revertToCheckpoint(pristineBuffer);
  }
};

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
  var editor;
  if (!((editor = this.active()) || (false === this.cfg('changedBackspace')))) {
    return this.activeEditor().backspace();
  }
  return editor.mutateSelectedText(function(sel, idx) {
    var cursor;
    if (sel.isEmpty()) {
      cursor = sel.cursor;
      while (cursor.isAtBeginningOfLine()) {
        cursor.moveLeft();
      }
      sel.selectLeft();
      sel.insertText(' ');
      return cursor.moveLeft();
    } else {
      return overwriteSelection(sel);
    }
  });
};

cmd["delete"] = function() {
  var editor;
  if (!((editor = this.active()) || (false === this.cfg('changedDelete')))) {
    return this.activeEditor()["delete"]();
  }
  return editor.mutateSelectedText(function(sel, idx) {
    var char, col, cur, range;
    if (!sel.isEmpty()) {
      return overwriteSelection(sel);
    }
    cur = sel.cursor;
    col = cur.getBufferColumn();
    char = cur.getCurrentBufferLine()[col];
    sel["delete"]();
    if (!editor.hasMultipleCursors()) {
      if (char === ' ') {
        return;
      }
    }
    range = sel.getBufferRange();
    editor.setTextInBufferRange(range, ' ');
    return sel.cursor.moveLeft();
  });
};

cmd.paste = function() {
  var clipboardText, cursor, editor, rc_pos, single;
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
  log("it paste stupid");
  return cursor.setScreenPosition(rc_pos);
};

cmd.smartInsert = function() {
  var column, cursor, editor, getIndent, hasSpacedArea, hasStructure, nonWord, ref, ref1, row, scope, sim, t0, t1;
  getIndent = function(line) {
    var spaces;
    try {
      spaces = /^ +/.exec(line)[0];
      return spaces.length;
    } catch (error1) {}
    return 0;
  };
  hasSpacedArea = function(line, start) {
    var areas, c, char, end, indent;
    if (start == null) {
      start = 0;
    }
    indent = getIndent(line);
    areas = [[indent, line.length, line]];
    if (start < indent) {
      start = indent;
    }
    end = line.length;
    c = 0;
    while (start !== end) {
      char = line[start];
      log("start=" + start + " char='" + char + "' c=" + c);
      if (char == null) {
        break;
      }
      if (char === ' ') {
        c++;
      } else {
        if (c > 1) {
          areas.push({
            s: start - c,
            e: start,
            b: char
          });
        }
        c = 0;
      }
      start++;
    }
    log("ends with start=" + start);
    return areas;
  };
  hasStructure = function(editor, bufferRow) {
    var a1, a2, a3, above, below, isChar, isDelim, line, similar, truth;
    isChar = function(char) {
      return /[a-zA-Z@]/.test(char);
    };
    isDelim = function(char) {
      return /[\(\)"'\{\}\[\]+-]/.test(char);
    };
    similar = function(row1, row2) {
      var area, b1, b2, e1, e2, i, j, l1, l1Indent, l1Len, l2, l2Indent, l2Len, len1, line1, line2, ref, ref1, ref2, ref3, s1, s2, truth;
      l1 = row1.slice(0);
      l2 = row2.slice(0);
      ref = l1.shift(), l1Indent = ref[0], l1Len = ref[1], line1 = ref[2];
      ref1 = l2.shift(), l2Indent = ref1[0], l2Len = ref1[1], line2 = ref1[2];
      if (l1Indent !== l2Indent) {
        return false;
      }
      truth = false;
      if (!l1.length) {
        if (l2.length > 0) {
          ref2 = [l2, l1], l1 = ref2[0], l2 = ref2[1];
        }
      }
      for (i = j = 0, len1 = l1.length; j < len1; i = ++j) {
        area = l1[i];
        s1 = area.s, e1 = area.e, b1 = area.b;
        if (l2[i] == null) {
          if (b1 === line2[e1]) {
            return true;
          }
        } else {
          ref3 = l2[i], s2 = ref3.s, e2 = ref3.e, b2 = ref3.b;
          if (e1 !== e2) {
            continue;
          }
          if (b1 !== b2) {
            return false;
          }
          if ((b1 === b2) && (e1 === e2)) {
            truth = true;
          }
        }
      }
      return truth;
    };
    truth = [];
    line = editor.lineTextForBufferRow(bufferRow);
    a1 = hasSpacedArea(line);
    above = editor.lineTextForBufferRow(bufferRow - 1);
    a2 = hasSpacedArea(above);
    log(line);
    log(above);
    log("------");
    log(a1);
    log(a2);
    truth.push(similar(a1, a2));
    below = editor.lineTextForBufferRow(bufferRow + 1);
    a3 = hasSpacedArea(below);
    truth.push(similar(a1, a3));
    return truth;
  };
  editor = this.activeEditor();
  ref = editor.getCursorBufferPosition(), row = ref.row, column = ref.column;
  console.log(hasStructure(editor, row));
  return;
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
  ref1 = editor.getCursorScreenPosition(), row = ref1.row, column = ref1.column;
  t0 = editor.lineTextForBufferRow(row);
  t1 = editor.lineTextForBufferRow(row + 1);
  console.log("indent is", ind(t0));
  return sim(t0, t1);
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
