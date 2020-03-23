# choose

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

```bash
$ brew install choose-gui
```

## Build

```bash
CXXFLAGS+=-stdlib=libc++ cargo build
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

```bash
$ ls | choose
```

## Roadmap

See [ROADMAP.md](./ROADMAP.md).

## License

See [MIT LICENSE](./LICENSE).
