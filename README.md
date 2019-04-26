# choose

*Fuzzy matcher for OS X that uses both std{in,out} and a native GUI*

---

- Gets list of items from stdin.
- Fuzzy-searches as you type.
- Sends result to stdout.
- Run choose -h for more info.
- [example vim integration](./choose.vim)
- [example emacs integration](./choose.el)

![animated screenshot](https://raw.githubusercontent.com/chipsenkbeil/choose/master/sshot/anim.gif)

## Install

~~~bash
$ brew install choose-gui
~~~

## Usage

~~~bash
$ ls | choose
~~~

## Roadmap

- [ ] Clean up code and/or port to something easier to work with (maybe something that can be platform-agnostic like ReasonML + [Revery](https://github.com/revery-ui/revery)/[Brisk](https://github.com/briskml/brisk)/[Cuite](https://github.com/let-def/cuite)
- [ ] Move vim to proper plugin structure and/or check desire from community to support
- [ ] Figure out the state of the emacs plugin (I don't use emacs) and/or check desire from community to support
- [ ] Write more documentation illustrating extra functionality

## License

> Released under MIT license.
>
> Original work Copyright (c) 2015 Steven Degutis
> 
> Modified work Copyright (c) 2019 Chip Senkbeil
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
