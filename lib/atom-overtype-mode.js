var CompositeDisposable, OvertypeMode, action, actions, cmd, pkg,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

CompositeDisposable = require('atom').CompositeDisposable;

actions = require('./actions.coffee');

pkg = require('../package.json');

OvertypeMode = (function() {
  function OvertypeMode() {
    this.onType = bind(this.onType, this);
  }

  OvertypeMode.prototype.statusBar = null;

  OvertypeMode.prototype.cmds = new CompositeDisposable();

  OvertypeMode.prototype.events = new CompositeDisposable();

  OvertypeMode.prototype.config = require('./config.coffee');

  OvertypeMode.prototype.caretClass = 'overtype-cursor';

  OvertypeMode.prototype.enabledEd = new Set();

  OvertypeMode.prototype.gcEditors = function() {
    var id, ids, j, len, ref, results;
    ids = atom.workspace.getTextEditors().map(function(e) {
      return e.id;
    });
    ref = Array.from(this.enabledEd);
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      id = ref[j];
      if (indexOf.call(ids, id) < 0) {
        results.push(this.enabledEd["delete"](id));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  OvertypeMode.prototype.active = function(editor) {
    if (editor == null) {
      editor = this.activeEditor();
      if (editor == null) {
        return;
      }
    }
    if (this.enabledEd.has(editor.id)) {
      return editor;
    }
  };

  OvertypeMode.prototype.settingsObserver = function(setting) {
    switch (setting.key) {
      case 'showIndicator':
        if (setting["new"] === 'no') {
          return this.sbItem.classList.add('hide-indicator');
        } else {
          return this.consumeStatusBar(this.statusBar);
        }
        break;
      case 'changeCaretStyle':
        return this.updateCursorStyle();
      default:
        return console.log("no action for '" + setting.key + "'");
    }
  };

  OvertypeMode.prototype.activate = function(state) {
    var cmd, method, ref;
    this.events.add(atom.config.onDidChange(pkg.name, (function(_this) {
      return function(arg) {
        var key, newValue, oldValue, setting, val;
        oldValue = arg.oldValue, newValue = arg.newValue;
        for (key in newValue) {
          val = newValue[key];
          if (oldValue[key] !== val) {
            setting = {
              key: key,
              old: oldValue[key],
              "new": val
            };
            break;
          }
        }
        console.log('change was', setting);
        return _this.settingsObserver(setting);
      };
    })(this)));
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
      })(this),
      pasteLikeLawrence: (function(_this) {
        return function() {
          return _this.pasteLikeLawrence();
        };
      })(this),
      smartInsert: (function(_this) {
        return function() {
          return _this.smartInsert();
        };
      })(this),
      backspace2col0: (function(_this) {
        return function() {
          return _this.backspace2col0();
        };
      })(this),
      backspace2lastcol: (function(_this) {
        return function() {
          return _this.backspace2lastcol();
        };
      })(this)
    };
    for (cmd in ref) {
      method = ref[cmd];
      this.cmds.add(atom.commands.add('atom-text-editor', 'overtype-mode:' + cmd, method));
    }
    this.events.add(atom.workspace.observeTextEditors((function(_this) {
      return function(editor) {
        return _this.prepareEditor(editor);
      };
    })(this)));
    return this.events.add(atom.workspace.onDidChangeActiveTextEditor((function(_this) {
      return function(editor) {
        if (editor == null) {
          return;
        }
        if (_this.active(editor)) {
          _this.enable();
        } else {
          _this.disable();
        }
        return _this.gcEditors();
      };
    })(this)));
  };

  OvertypeMode.prototype.test = function() {
    return console.log("test called");
  };

  OvertypeMode.prototype.cfg = function(key) {
    return atom.config.get([pkg.name, key].join('.'));
  };

  OvertypeMode.prototype.activeEditor = function() {
    return atom.workspace.getActiveTextEditor();
  };

  OvertypeMode.prototype.consumeStatusBar = function(statusBar) {
    this.statusBar = statusBar;
    this.setupIndicator();
    if ('overwrite' === this.cfg('startMode')) {
      return this.enable();
    }
  };

  OvertypeMode.prototype.getLineEnding = function() {
    var codes, j, len, lineEnding, ref, ref1, ref2, ref3, tile, tiles;
    codes = {
      'LF': '\n',
      'CRLF': '\r\n'
    };
    tiles = this.statusBar.getRightTiles();
    ref = tiles.concat(this.statusBar.getLeftTiles());
    for (j = 0, len = ref.length; j < len; j++) {
      tile = ref[j];
      if (!((ref1 = tile.item) != null ? (ref2 = ref1.element) != null ? (ref3 = ref2.classList) != null ? ref3.contains('line-ending-tile') : void 0 : void 0 : void 0)) {
        continue;
      }
      lineEnding = tile.item.element.text;
      break;
    }
    return codes[lineEnding || 'LF'];
  };

  OvertypeMode.prototype.setupIndicator = function() {
    if (this.sbItem == null) {
      this.sbItem = document.createElement('div');
      this.sbItem.classList.add('inline-block');
      this.sbItem.classList.add('mode-insert');
      this.sbItem.textContent = 'INS';
      this.sbItem.addEventListener('click', (function(_this) {
        return function() {
          return _this.toggle();
        };
      })(this));
      this.sbTooltip = atom.tooltips.add(this.sbItem, {
        title: 'Mode: Insert'
      });
    }
    if (this.sbTile != null) {
      this.sbTile.destroy();
    }
    switch (this.cfg('showIndicator')) {
      case 'left':
        this.sbItem.classList.remove('hide-indicator');
        return this.sbTile = this.statusBar.addLeftTile({
          item: this.sbItem,
          priority: 50
        });
      case 'right':
        this.sbItem.classList.remove('hide-indicator');
        return this.sbTile = this.statusBar.addRightTile({
          item: this.sbItem,
          priority: 50
        });
      case 'no':
        return this.sbItem.classList.add('hide-indicator');
    }
  };

  OvertypeMode.prototype.deactivate = function() {
    var ref;
    this.disable();
    this.events.dispose();
    this.cmds.dispose();
    if ((ref = this.sbTile) != null) {
      ref.destroy();
    }
    if (this.sbItem != null) {
      this.sbItem = null;
    }
    atom.workspace.getTextEditors().map(function(editor) {
      if (editor.pristine_insertNewline != null) {
        editor.enter = editor.pristine_insertNewline;
        return editor.pristine_insertNewline = null;
      }
    });
    return this.enabledEd.clear();
  };

  OvertypeMode.prototype.toggle = function() {
    var editor;
    if (!(editor = this.activeEditor())) {
      return;
    }
    this.getLineEnding();
    if (this.active(editor)) {
      this.enabledEd["delete"](editor.id);
      this.disable();
    } else {
      this.enabledEd.add(editor.id);
      this.enable();
    }
    if (this.cfg('changeCaretStyle')) {
      this.updateCursorStyle();
    }
    return console.log('toggle::', this.enabledEd.size, Array.from(this.enabledEd));
  };

  OvertypeMode.prototype.enable = function() {
    if ('no' === this.cfg('showIndicator')) {
      return;
    }
    this.sbTooltip = atom.tooltips.add(this.sbItem, {
      title: 'Mode: Overwrite'
    });
    this.sbItem.textContent = 'DEL';
    if (this.hidden) {
      this.sbItem.classList.remove('hide-indictator');
    }
    this.sbItem.classList.remove('mode-insert');
    return this.sbItem.classList.add('mode-overwrite');
  };

  OvertypeMode.prototype.disable = function() {
    if ('no' === this.cfg('showIndicator')) {
      return;
    }
    this.sbTooltip = atom.tooltips.add(this.sbItem, {
      title: 'Mode: Insert'
    });
    this.sbItem.textContent = 'INS';
    if (this.hidden) {
      this.sbItem.classList.remove('hide-indictator');
    }
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
      if (this.active(editor)) {
        results.push(view.classList.add(this.caretClass));
      } else {
        results.push(view.classList.remove(this.caretClass));
      }
    }
    return results;
  };

  OvertypeMode.prototype.prepareEditor = function(editor) {
    if (this.cfg('changedReturn')) {
      if (editor.pristine_insertNewline == null) {
        editor.pristine_insertNewline = editor.insertNewline;
        editor.insertNewline = (function(_this) {
          return function() {
            return _this.enter();
          };
        })(this);
      }
    }
    editor.observeSelections((function(_this) {
      return function(sel) {
        var fitsCurrentLine, isAutocompleteInsert;
        if (sel.pristine_insertText == null) {
          sel.pristine_insertText = sel.insertText;
        }
        isAutocompleteInsert = function(sel, txt) {
          var selLen, selTxt, txtLen;
          selTxt = sel.getText();
          selLen = selTxt.length;
          txtLen = txt.length;
          return ((2 < selLen && selLen < txtLen)) && (txt.startsWith(selTxt));
        };
        fitsCurrentLine = function(sel, selLen, txtLen) {
          var lineLen, start;
          start = sel.getBufferRange().start;
          lineLen = sel.editor.lineTextForBufferRow(start.row).length;
          return (lineLen - start.column + selLen - txtLen) > 0;
        };
        return sel.insertText = function(txt, opts) {
          var end, selLen, txtLen;
          if (!_this.active()) {
            return sel.pristine_insertText(txt, opts);
          } else if (!_this.cfg('enableAutocomplete')) {
            console.log("auto-complete", _this.cfg('enableAutocomplete'));
            return sel.pristine_insertText(txt, opts);
          }
          if (!isAutocompleteInsert(sel, txt)) {
            return sel.pristine_insertText(txt, opts);
          }
          editor = sel.editor;
          selLen = sel.getText().length;
          txtLen = txt.length;
          if (fitsCurrentLine(sel, selLen, txtLen)) {
            sel["delete"]();
            editor.selectRight(txtLen - selLen);
            return sel.pristine_insertText(txt, opts);
          } else {
            sel["delete"]();
            sel.selectToEndOfLine();
            sel.pristine_insertText(txt, opts);
            end = sel.getBufferRange().end;
            return editor.setCursorBufferPosition(end);
          }
        };
      };
    })(this));
    this.updateCursorStyle();
    return this.events.add(editor.onWillInsertText(this.onType));
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

  OvertypeMode.prototype.onType = function(evt) {
    var editor, j, len, ref, results, sel, x;
    if (!(editor = this.active())) {
      return;
    }
    if (!(window.event instanceof TextEvent)) {
      return;
    }
    ref = editor.getSelections();
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      sel = ref[j];
      if (sel.isEmpty()) {
        if (sel.cursor.isAtEndOfLine()) {
          continue;
        }
        console.log("onType::selectRight");
        if (evt.text.length === 1) {
          results.push(sel.selectRight());
        } else {
          results.push((function() {
            var k, ref1, results1;
            results1 = [];
            for (x = k = 1, ref1 = evt.text.length; 1 <= ref1 ? k <= ref1 : k >= ref1; x = 1 <= ref1 ? ++k : --k) {
              console.log('selectRight');
              results1.push(sel.selectRight());
            }
            return results1;
          })());
        }
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  return OvertypeMode;

})();

for (cmd in actions) {
  action = actions[cmd];
  OvertypeMode.prototype[cmd] = action;
}

module.exports = new OvertypeMode;
