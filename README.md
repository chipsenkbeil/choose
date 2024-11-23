# choose

![GitHub release (latest by date)](https://img.shields.io/github/v/release/chipsenkbeil/choose)

*Fuzzy matcher for OS X that uses both std{in,out} and a native GUI*

---

- Gets list of items from stdin.
- Fuzzy-searches as you type.
- Sends result to stdout.
- Run choose -h for more info.
- [example vim integration](./choose.vim)
- [example emacs integration](./choose.el)

![Animated Screenshot](/../Assets/screenshots/anim.gif?raw=true "Animated Screenshot")

## Install

For the latest release, go to [the releases
section](https://github.com/chipsenkbeil/choose/releases) and download the
binary.

### Homebrew installation

> Keep in mind that we do not maintain the homebrew formula here! So check the
> version you have via `choose -v` and compare it to the latest version in [the
> releases section](https://github.com/chipsenkbeil/choose/releases) .

```bash
brew install choose-gui
```

### Build and Install Documentation

From root of repository, run:

```bash
make docs
make install-docs
```

You can then issue `man choose` to read the manual.

Note that this requires `pandoc` to be installed on your system to build the
manual page.

## Usage

### List the content from current directory

```bash
ls | choose
```

### Open apps from the applications directories

```bash
ls /Applications/ /Applications/Utilities/ /System/Applications/ /System/Applications/Utilities/ | \
    grep '\.app$' | \
    sed 's/\.app$//g' | \
    choose | \
    xargs -I {} open -a "{}.app"
```

### Use as a snippet manager

Suppose you have some snippets in a text file and you want to quickly search and
paste them with choose. Here is a command that you can bind to some shortcut
with something like Karabiner:
```bash
cat snippets_separated_with_two_newline_symbols.txt \
    | choose -e -m -x \n\n - \
    | pbcopy - \
    && osascript -e 'tell application "System Events" to keystroke "v" using command down'
```

This will prompt choose, get its output, copy it to pasteboard, and trigger a
paste shortcut `command+v`. 

For this to work in Karabiner, you need to give it access via 

```
Privacy & Security -> Accessibility -> karabiner_console_user_server 
```

Typically located at `/Library/ApplicationSupport/org.pqrs/Karabiner-Elements/bin/karabiner_console_user_server`,
otherwise you will get `System Events got an error: osascript is not allowed to send keystrokes. (1002)`

## License

See [MIT LICENSE](./LICENSE).
