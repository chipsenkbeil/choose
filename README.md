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

## License

See [MIT LICENSE](./LICENSE).
