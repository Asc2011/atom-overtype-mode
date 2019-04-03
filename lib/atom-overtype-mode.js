var CompositeDisposable, OvertypeMode;

CompositeDisposable = require('atom').CompositeDisposable;

OvertypeMode = (function() {
  function OvertypeMode() {}

  OvertypeMode.prototype.active = false;

  OvertypeMode.prototype.cmds = new CompositeDisposable();

  OvertypeMode.prototype.events = new CompositeDisposable();

  OvertypeMode.prototype.config = require('./config.coffee');

  OvertypeMode.prototype.className = 'overtype-cursor';

  OvertypeMode.prototype.activate = function(state) {
    var cmd, method, ref;
    ref = {
      toggle: (function(_this) {
        return function() {
          return _this.toggle();
        };
      })(this),
      "delete": (function(_this) {
        return function() {
          return _this["delete"]();
        };
      })(this),
      backspace: (function(_this) {
        return function() {
          return _this.backspace();
        };
      })(this),
      pasteOver: (function(_this) {
        return function() {
          return _this.pasteOver();
        };
      })(this)
    };
    for (cmd in ref) {
      method = ref[cmd];
      this.cmds.add(atom.commands.add('atom-text-editor', 'overtype-mode:' + cmd, method));
    }
    return this.events.add(atom.workspace.observeTextEditors((function(_this) {
      return function(editor) {
        return _this.prepareEditor(editor);
      };
    })(this)));
  };

  OvertypeMode.prototype.cfg = function(key) {
    return atom.config.get('atom-overtype-mode.' + key);
  };

  OvertypeMode.prototype.activeEditor = function() {
    return atom.workspace.getActiveTextEditor();
  };

  OvertypeMode.prototype.consumeStatusBar = function(statusBar) {
    var ref, ref1;
    if ((ref = this.sbItem) != null) {
      ref.dispose();
    }
    if ('no' !== this.cfg('showIndicator')) {
      this.sbItem = document.createElement('div');
      this.sbItem.classList.add('inline-block');
      this.sbItem.classList.add('mode-insert');
      this.sbItem.textContent = 'INS';
      this.sbItem.addEventListener('click', (function(_this) {
        return function() {
          return _this.toggle();
        };
      })(this));
      if ((ref1 = this.sbTooltip) != null) {
        ref1.dispose();
      }
      this.sbTooltip = atom.tooltips.add(this.sbItem, {
        title: 'Mode: Insert'
      });
    }
    if ('left' === this.cfg('showIndicator')) {
      this.sbTile = statusBar.addLeftTile({
        item: this.sbItem,
        priority: 50
      });
    } else if ('right' === this.cfg('showIndicator')) {
      this.sbTile = statusBar.addRightTile({
        item: this.sbItem,
        priority: 50
      });
    }
    if ('overwrite' === this.cfg('startMode')) {
      return this.enable();
    }
  };

  OvertypeMode.prototype.deactivate = function() {
    var ref, ref1;
    this.disable();
    this.events.dispose();
    this.cmds.dispose();
    if ((ref = this.sbItem) != null) {
      ref.destroy();
    }
    if ((ref1 = this.sbTile) != null) {
      ref1.destroy();
    }
    if (this.sbItem != null) {
      this.sbItem = null;
      return this.sbTile = null;
    }
  };

  OvertypeMode.prototype.toggle = function() {
    if (this.active) {
      this.disable();
    } else {
      this.enable();
    }
    if (this.cfg('changeCaretStyle')) {
      return this.updateCursorStyle();
    }
  };

  OvertypeMode.prototype.enable = function() {
    this.active = true;
    if ('no' === this.cfg('showIndicator')) {
      return;
    }
    this.sbTooltip = atom.tooltips.add(this.sbItem, {
      title: 'Mode: Overwrite'
    });
    this.sbItem.textContent = 'DEL';
    this.sbItem.classList.remove('mode-insert');
    return this.sbItem.classList.add('mode-overwrite');
  };

  OvertypeMode.prototype.disable = function() {
    this.active = false;
    if ('no' === this.cfg('showIndicator')) {
      return;
    }
    this.sbTooltip = atom.tooltips.add(this.sbItem, {
      title: 'Mode: Insert'
    });
    this.sbItem.textContent = 'INS';
    this.sbItem.classList.remove('mode-overwrite');
    return this.sbItem.classList.add('mode-insert');
  };

  OvertypeMode.prototype.updateCursorStyle = function() {
    var editor, j, len, ref, results, view;
    if (!this.cfg('changeCaretStyle')) {
      return;
    }
    ref = atom.workspace.getTextEditors();
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      editor = ref[j];
      view = atom.views.getView(editor);
      if (this.active) {
        results.push(view.classList.add(this.className));
      } else {
        results.push(view.classList.remove(this.className));
      }
    }
    return results;
  };

  OvertypeMode.prototype.prepareEditor = function(editor) {
    this.updateCursorStyle();
    return this.events.add(editor.onWillInsertText((function(_this) {
      return function() {
        return _this.onType(editor);
      };
    })(this)));
  };

  OvertypeMode.prototype.info = function(editor) {
    var i, j, len, log, results, sel, selectedText, sels;
    log = console.log;
    log("multiple cursors", editor.hasMultipleCursors());
    selectedText = editor.getSelectedText();
    sels = editor.getSelections();
    log("has " + sels.length + "-selection-len=" + selectedText.length + " '" + selectedText + "'");
    results = [];
    for (i = j = 0, len = sels.length; j < len; i = ++j) {
      sel = sels[i];
      results.push(log("\tsel-" + i, sel.getScreenRange()));
    }
    return results;
  };

  OvertypeMode.prototype.backspace = function() {
    var cursor, editor, normalBS;
    editor = this.activeEditor();
    this.info(editor);
    normalBS = function() {
      return editor.backspace();
    };
    if (!this.active) {
      return normalBS();
    }
    if (!this.cfg('changedBackspace')) {
      return normalBS();
    }
    cursor = editor.getLastCursor();
    if (cursor.isAtBeginningOfLine()) {
      return;
    }
    editor.selectLeft();
    return editor.mutateSelectedText(function(sel, idx) {
      sel.insertText(' ', {
        select: true
      });
      return sel.clear();
    });
  };

  OvertypeMode.prototype["delete"] = function() {
    var cursor, editor, j, len, range, ref, results, sel, spaces, txt;
    editor = this.activeEditor();
    if (this.active && this.cfg('changedDelete')) {
      ref = editor.getSelections();
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        sel = ref[j];
        txt = sel.getText();
        if (txt.length > 1) {
          spaces = Array(txt.length).join(' ');
          range = sel.getScreenRange();
          sel.insertText(spaces);
          cursor = editor.getLastCursor();
          results.push(cursor.setScreenPosition([range.start.row, range.start.column]));
        } else {
          editor["delete"]();
          editor.insertText(' ');
          results.push(editor.moveLeft());
        }
      }
      return results;
    } else {
      return editor["delete"]();
    }
  };

  OvertypeMode.prototype.pasteOver = function() {
    var editor, range, text;
    editor = this.activeEditor();
    if (!this.active) {
      return editor.pasteText();
    }
    text = atom.clipboard.read();
    if (text.length === 0) {
      return;
    }
    editor.selectRight(text.length);
    range = editor.insertText(text);
    return console.log("insertText gave", range);
  };

  OvertypeMode.prototype.onType = function(editor) {
    var j, len, ref, results, selection;
    if (!this.active) {
      return;
    }
    if (!(window.event instanceof TextEvent)) {
      return;
    }
    ref = editor.getSelections();
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      selection = ref[j];
      if (selection.isEmpty() && selection.cursor.isAtEndOfLine()) {
        continue;
      }
      if (selection.isEmpty()) {
        results.push(selection.selectRight());
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  return OvertypeMode;

})();

module.exports = new OvertypeMode;
