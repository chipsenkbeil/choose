## Monitor Selection

You can now specify which display the choose GUI appears on via the `--monitor` (or `-M`) command-line flag.

Monitor selection supports:
- Index: `choose --monitor 1` (secondary screen, zero-based)
- Display ID: `choose --monitor 459283490`
- Display name: `choose --monitor "Color LCD"`

If the specified monitor can't be detected, choose will fall back to the default main display.

Example:
```bash
ls | choose --monitor 1
```