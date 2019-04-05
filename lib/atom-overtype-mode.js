var CompositeDisposable, OvertypeMode, action, actions, key;

CompositeDisposable = require('atom').CompositeDisposable;

actions = require('./actions.coffee');

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
      paste: (function(_this) {
        return function() {
          return _this.paste();
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
    if (this.cfg('changedReturn')) {
      if (editor._insertNewline == null) {
        editor._insertNewline = editor.insertNewline;
        editor.insertNewline = (function(_this) {
          return function() {
            return _this.enter();
          };
        })(this);
      }
    }
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

for (key in actions) {
  action = actions[key];
  OvertypeMode.prototype[key] = action;
}

module.exports = new OvertypeMode;
