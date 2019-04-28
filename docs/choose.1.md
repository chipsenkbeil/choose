---
title: 'choose'
section: 1
header: 'General Commands Manual'
footer: 'MIT'
date: 'April 27, 2019'
---

# NAME

**choose** - Fuzzy matcher for OS X that uses both std{in,out} and a native GUI

# SYNOPSIS

**choose** \[*options*\]

# DESCRIPTION

**choose** is a small, graphical program that gets a list of items from
stdin, displays the list as a series of choices with the ability to fuzzily
search, and prints out the selected item after being selected.

## OPTIONS

-i

: Return index of selected element

-v

: Print version of choose

-n *rows*

: Set number of rows (default: 10)

-w *width*

: Set width of window (default: 50)

-f *font*

: Set font used by window (default: Menlo)

-s *size*

: Set font size used by window (default: 26)

-c *color*

: Set highlight color for matched string (default: 0000FF)

-b *color*

: Set background color of selected elements (default: 222222)

-u

: Disable underline and use background for matched string

-m

: Return the query string in case it doesn't match any item

# EXAMPLES

The following displays **choose** for the current directory's contents

    ls | choose

# BUGS

None known so far.

# AUTHOR

| **choose** was started by Steven Degutis in 2015.
| Ownership was transferred in 2019 to Chip Senkbeil.

# COPYRIGHT

choose is provided under the MIT license.

| Original work Copyright (c) 2015 Steven Degutis
| Modified work Copyright (c) 2019 Chip Senkbeil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
