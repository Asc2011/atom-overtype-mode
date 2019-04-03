# Changelog

## 0.5.0
- added mode-indicator inside the atom-status-bar. Implements [issue-#19](https://github.com/brunetton/atom-overtype-mode/issues/19)
- adjusted behaviour of `backspace`-key during overtype-mode. Partial-fix for [issue-#12](https://github.com/brunetton/atom-overtype-mode/issues/12)
- adjusted behaviour of `delete`-key during overwrite-mode.
- adjusted behaviour of `paste-from-clipboard` during overwrite-mode.
- settings-section :
  - added option to enable/disable of cursor-styling.
  - added option to hide or position the mode-indicator.
  - made all other options configurable.


## 0.4.0
- Fixed error in Atom 1.19

## 0.3.4
- Require Atom version >= 1.13. The updated selectors aren't available in earlier versions.

## 0.3.3
- Fix deprecated CSS selectors. Thanks to @mateddy for PR #17.

## 0.3.2
- Fix erratic behaviour after opening new files

## 0.3.1
- Updated documentation

## 0.3.0
- Compatibility with Atom 1.2.0 (Thanks to @Yoshi325)
- Better support for multiple selections
- Grouped undo/redo. It is no longer necessary to press Ctrl+Z for each character typed.

## 0.2.3 - update to shadow DOM
- Fix #5. Thanks again @muchweb for his contribution to make it compatible with [shadow DOM](https://atom.io/docs/latest/upgrading/upgrading-your-syntax-theme)

## 0.2.2 - theme changes
- Thanks to @muchweb for his contribution around cursor appearance

## 0.2.1
- First published version
