# Overtype-mode for Atom

Switch beetween insert- and overwrite-mode by using `Ins`-key.
Since on Mac/plat-darwin there is no `Insert`-key this package starts automaticly. It places a switch into the status-bar to choose between `overwrite`- and `insert`-mode. The startup-mode is a configurable-option.

The cursor turns into a rectangle to indicate that overtype is enabled. This is now a configurable-option. It can be disabled in favour of other block-cursor-packages e.g. *Simple-block-cursor*.

The behaviour of `backspace`-, `delete`-,`return`-keys during `overtype-mode` was adjusted. These are configurable-options.
actions to replace `editor:delete-to-end-of-line` and `editor:delete-to-beginning-of-line` were added.


## ToDo
- make use of Notifications & logging to devtools-console.
- ++ adjust paste-operations during overwrite-mode. See [issue-#14](https://github.com/brunetton/atom-overtype-mode/issues/14) and [issue-#15](https://github.com/brunetton/atom-overtype-mode/issues/15)
- try some 'peek-paste'-action, that visually marks the region to overwrite, before actually triggering a overwrite-operation.
- ++ fixed insertions of auto-completed text. see [issue-#13](https://github.com/brunetton/atom-overtype-mode/issues/13). Needs testing.
  - autocomplete-plus.strictMatching = on
  - autocomplete-plus.minimumWordLength = 3

- ++ check-for & proper-handling of active-selections when delete & backspace-keypresses or paste-events happen in overwrite-mode.
- cross-package tests - might there be other commonly used packages that collide/conflict with `overtype-mode` ?
  - glich: insertions from col-0 fail, !setting `AtomicSoftTabs`!
  - glitch: pair-insertions by `bracket-matcher`.
- ++ make the package extensible and completly configurable via atoms-settings-view.
- ++ bug: after deactivation via settings-view the re-activation fails ? fixed & done, Disposable. see [issue-#22](https://github.com/brunetton/atom-overtype-mode/issues/22)
- ++ mode-activation on a per TextEditor basis. Use state-serialization ? Prbl. not needed.


## Future
- investigate why _**snippet**_-insertions does'nt work ? Seems snippets from `autocomplete-plus` do work !
- provide a minimal implementation for vertical cut/copy/paste-operations.
- (+) observe configuration-changes ? and act upon changes...
- add some more screen-shots.
- prettify the on-/off-look of the mode-indicator.

![](http://i.imgur.com/DejekQN.gif)
