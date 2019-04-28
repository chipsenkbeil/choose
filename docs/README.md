# choose Docs

Contains documentation for the **choose** program including man pages.

## Building man pages

In order to build man pages for **choose**, the following programs must be
available and in your `PATH`:

- [GNU Make](https://www.gnu.org/software/make/) (tested using version 3.81+)
- [Pandoc](https://pandoc.org/) (tested using version 2.5+)

Run `make` from the `docs/` directory to build the man pages and `make
install` to copy the man pages to appropriate locations.

Issuing `make uninstall` will remove man pages from appropriate locations and
`make clean` will delete the locally-built man pages.

Additionally, from the root of the project, you can build the man pages using
`make docs`, install via `make install-docs`, and uninstall via `make
uninstall-docs`.
