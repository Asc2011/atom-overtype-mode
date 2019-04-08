# Overtype-mode for Atom

Switch beetween insert- and overwrite-mode by using `Ins`-key.
Since on Mac/plat-darwin there is no `Insert`-key this package starts automagicly. It adds a switch into the status-bar choose between `overwrite`- and `insert`-mode. The startup-mode is a configurable-option.

The cursor turns into a rectangle to indicate that overtype is enabled. This is now a configurable-option. It can be disabled in favour of other block-cursor-packages e.g. *Simple-block-cursor*.

The behaviour of `backspace`- and `delete`-keys during `overtype-mode` was adjusted. This is a configurable-option.


## TODO / Future
- (+) make this package easily extensible and completly configurable via atoms-settings-view.
- (+) mode-activation on a per TextEditor basis. Check for state-serialization ?
- fix insertions of auto-completed text. see [issue-#13](https://github.com/brunetton/atom-overtype-mode/issues/13)
- bug: after deactivation via settings-view the re-activation fails ?
- cross-package tests - might there be other commonly used packages that collide/conflict with `overtype-mode` ?
- (+) check-for & proper-handling of active selections when delete & backspace-keypresses or paste-events happen in overwrite-mode.
- (+) adjust paste-operations during overwrite-mode. See [issue-#14](https://github.com/brunetton/atom-overtype-mode/issues/14) and [issue-#15](https://github.com/brunetton/atom-overtype-mode/issues/15)
- add some more screen-shots.
- prettify the on-/off-look of the mode-indicator.
- observe configuration-changes ?


![](http://i.imgur.com/DejekQN.gif)
