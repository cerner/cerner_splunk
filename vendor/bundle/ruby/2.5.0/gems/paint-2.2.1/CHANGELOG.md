# CHANGELOG

### 2.2.1

* Explicitly set mac's Terminal.app to 256 colors only, fixes #28

### 2.2.0

* Support NO_COLOR environment variable, implements #26 (see no-color.org)

### 2.1.1

* Blacklist True Color support for urxvt, fixes #25

### 2.1.0

* Set True Color as default mode on more terminals, patch by @smoochbot

### 2.0.3

* Add `gray` alias for `white` color, patch by @AlexWayfer

### 2.0.2

* Remove `gunzip` deprecation warning

### 2.0.1

*   Fix nested substitutions, patch by @mildmojo

### 2.0.0
#### Major Changes

*   New default color mode `0xFFFFFF`: 24bit - true color. If this breaks your code, add `Paint.mode = 256` to the beginning of your code
*   New `Paint%[]` API: Substitution mechanism for nested color strings

#### Minor Changes

*   Smaller gem size (compress RGB color name data)
*   Remove `Paint.update_rgb_colors` and `Paint.rainbow`
*   Internal method `.hex` renamed to `.rgb_hex` and does not take "#" prefixed strings anymore
*   Minor refactorings and documentation updates

### 1.0.1

*   Fix case of string arguments getting mutated (see gh#14)


### 1.0.0

*   Improved performance
*   Option for :random colors removed (see readme)
*   Separate Paint::SHORTCUTS into extra gem
*   Drop support for Ruby 1 (inoffically still support 1.9.3)


### 0.9.0

*   Don't colorize strings via shortcuts when Paint.mode == 0
*   Freeze bundled ascii color data


### 0.8.7

*   Fix caching bug for random ansi color


### 0.8.6

*   Add missing require 'rbconfig' and travis test everything


### 0.8.5

*   Support 256 color on windows' ConEmu


### 0.8.4

*   Fix post-install message unicode


### 0.8.3

*   Paint.[] also accepts uppercased hex strings (gh#2)
*   Performance tweaks (thanks to murphy) (gh#4, #5)
    *   API change: deactivate colorizing with Paint.mode = 0


### 0.8.2

*   Paint.[] with only a single string argument does not colorize the string
    anymore, but returns the plain string
*   New pseudo color :random - returns a random ansi color


### 0.8.1

*   Improve rgb function with better gray scale values
*   Add Paint.mode:
    *   Set to 0 to deactivate colorizing
    *   Set to 16 or 8 and all color generation methods will generate simple
        ansi colors
    *   Set to 256 for 256 color support
    *   Tries to automatically detect your terminal's features
*   Minor changes


### 0.8.0

*   Initial release

