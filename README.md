# Overtype mode for Atom

Switch beetween insert- and overwrite-mode by using `Ins`-key.
Since on Mac/plat-darwin there is no `Insert`-key this package starts automagic. It adds a switch into the status-bar to (de-)activate `overwrite`- and `insert`-mode. The startup-mode is a configurable-option.

The cursor turns into a rectangle to indicate that overtype is enabled. This is now a configurable-option. It can be disabled in favour of other block-cursor-packages e.g. *Simple-block-cursor*.

The behaviour of `backspace`- and `delete`-keys during overwrite-mode was adjusted. This is a configurable-option.


## TODO / Future
- bug: after deactivation via settings-view the re-activation fails ?
- check-for & proper-handle of active selections when delete & backspace-keypresses happen in overwrite-mode.
- adjust cut & paste-operations during overwrite-mode. See [issue-#14](https://github.com/brunetton/atom-overtype-mode/issues/14) and [issue-#15](https://github.com/brunetton/atom-overtype-mode/issues/15)
- add more screen-shots
- prettify the on-/off-look of the mode-indicator.
- observe configuration-changes ?


![](http://i.imgur.com/DejekQN.gif)
