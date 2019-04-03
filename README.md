# Overtype mode for Atom

Switch beetween insert and overtype mode by using `Ins` key.
Since on Mac/plat-darwin there is no `Insert`-key this package starts automagically. It places a switch in the status-bar to (de-)activate `overtype`- and `insert`-mode.

The cursor turns into a rectangle to indicate that overtype is enabled. This is a configurable-option. This can be disabled in favour of other block-cursor-packages.

The behaviour of `backspace`- and `delete`-keys during overtype-mode was adjusted. This is a configurable option.


## TODO
- check-for & proper-handle of active selections when delete & backspace-keypresses happen during overwrite-mode.
- adjust cut & paste-operations during overwrite-mode.
- prettify the on-/off-look of the mode-indicator.
- observe configuration-changes ?


![](http://i.imgur.com/DejekQN.gif)
