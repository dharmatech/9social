# Learning `rc` for 9social

This project is expected to use idiomatic Plan 9 / 9front shell style.
For small client commands such as `9social/cmd/follow`, start by learning `rc` from original 9front materials rather than from POSIX shell habits.

## Read First

Read these before writing or reviewing `rc` scripts:

* `/sys/doc/rc.ms`
  Tom Duff's `rc` paper. This is the best high-level explanation of the language and its design.
* `man rc`
  Use this for exact syntax and operational details.

These two references are enough to get the language model right:

* variables are lists, not Bourne-style strings
* quoting rules are different
* `$status` matters
* redirection syntax matters
* `if`, `if not`, `switch`, and command substitution are used differently than in POSIX shells

## Inspect Real Scripts

After reading the paper and man page, inspect shipped `rc` scripts to pick up idiomatic style.

Good examples:

* `/bin/9fs`
  Good example of a real command script with usage handling, stderr output, `switch`, `if not`, and filesystem checks.
* `/bin/cpurc`
  Useful larger example of everyday 9front `rc` style.
* `/sys/lib/dist/mail/lib/msgcat.rc`
  Small script with functions, `switch`, and direct text processing.
* `/sys/lib/dist/mail/lib/spam.rc`
  Small linear script doing temporary-file and pipeline work.
* `/sys/lib/lp/bin/lpsend.rc`
  Small command-oriented script with error/exit handling.

## Search For More Examples

Inside 9front, use `g` to search for more `rc` scripts:

```sh
cd /sys/lib
g '^#!/bin/rc'
```

Also inspect likely script locations such as:

* `/bin`
* `/rc`
* `/sys/lib`

Searching the whole root can be noisy because of mounted namespaces and transient files, so prefer targeted searches.

## Working Rule

Before implementing a new 9social command in `rc`:

1. Read `/sys/doc/rc.ms` and `man rc` if the details are not fresh.
2. Inspect one or two shipped scripts that are close in size and purpose.
3. Prefer idiomatic `rc` constructs over Bourne/POSIX shell habits.

This file is only a pointer for how to learn `rc`.
Do not treat it as a replacement for the paper, the man page, or real 9front scripts.
