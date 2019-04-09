
## 0.5.0 Release

Aside some bug-fixes, this release carries some crucial changes. Most of these are by default deactivated, in order to let you choose the ones you prefer. Use the new settings-section to try out new behaviors of _Backspace-/Delete-/Paste_-actions or to enable insertions triggered by *autocomplete*.

### Main idea
The concept behind and reason for this mode-of-operation is providing support for editing texts that already carry a structure, that one wants to preserve while editing. This might be indented-source-code or table-like documents. **TextPad** and other editors offer such a mode-of-operation commonly found by the name _'overwrite'_-mode.
In that spirit this package tries to avoid making changes to the layout of the document. Notice that any behavior can be enabled or disabled. These are in detail :
- hitting **Backspace** yields a step to the left while overwriting the character with a SPACE-char. It won't move the right-side of the cursor and refuses to overwrite/delete line-endings. Instead it walks over until it reaches a char.
- hitting **Delete** replaces the char under the cursor with a SPACE-char. It won't overwrite/delete line-endings. When there already is a SPACE-char under the curser, then it will remove that SPACE-char and as a consequence shift-left the rest-of-the-line.
- hitting **Enter** only moves the curser to the start of the following-line. It won't insert a line-feed. Unless the cursers-position is the last-line of the document. Only then a new-line will be inserted.
- using **autocomplete** is now possible. It destructively overwrites as-many-chars-as-needed to the right of the caret. If the current line does not provide enough space to insert the auto-completion-term, then it will expand the current-line. Thus preserving the structure.
 
 
The status-bar-indicator is enabled by default. It will by default display on the right-side of the status-bar. Other options are **left** oder **hide**. It will start in `Insert`-Mode '**INS**', which is the standard-mode of operation in Atom. When `overtype`-mode gets activated, the status-bar shows '**Del**'. The mode-activation ~~used to be global~~ for all text-editors. This has changed, it can and has to be be toggled on/off seperatly for each text-editor-instance. Besides the keyboard-shortcut for toggling, one can mouse-click the mode-indicator.
As said above, the package (auto-) starts in `Insert`-mode. This can be changed via the settings-section.

#### Contributions & Additions & Extensions
The code-structure is designed to make changes or additions as easy as possible. The code is largely documented. Take a look at `./lib/actions.coffee` to get an idea. [Atoms API](https://atom.io/docs/api/v1.35.1/TextEditor) makes such a task quite easy. A while ago [Bruno Duyé](https://github.com/brunetton), the owner of this package, had started a ES6-rewrite of the code. I doubt he will release it anytime soon. I have no plans for a ES6-rewrite.
If you extend or adjust the package, feel free to submit an issue or even a pull-request. I'd prefer contributions in [Coffeescript](https://coffeescript.org), but that is your choice.

#### Word of Caution
Ironcally i develop and use this package on OsX/`plat-darwin`, where we there is no `Insert`-key. I can only test this platform. If smth. does not work on your platform, don't hesitate to [submit an issue](https://github.com/brunetton/atom-overtype-mode/issues).
The new features have not seen much testing. Be warned and expect to discover edge-cases.

 ##### Interactions with other packages
 - one can disable the styling of the caret/cursors in `overwrite`-mode. I do so, in favour of the *[simple-block-cursor](https://atom.io/packages/simple-block-cursor)*-package.
 - i found Atom's auto-indent-feature to be the cause of a minor glitch. Insertion at the beginning-of-a-line sometimes failed or the rest-of-the-line shifted to the left. After i had turned the feature off, this went away. There are a bunch of `auto-indent`-packages around. It's not possible for me to test against those. If you encounter problems try to disable your `indention`-helper and see if your problem goes away.
