# Performance Experiments

This directory contains manual performance experiments for 9social.

These scripts are not part of `tests/run.rc`. They may create large simulated
9social communities, generate many posts, replies, and likes, and take noticeable
time to run.

The goals are:

- measure indexing cost on larger datasets
- measure interactive command latency, especially `Like` and `Reply`
- provide large simulated environments for manual browsing in acme
- explore performance changes before changing production behavior

Generated data should live under `/tmp/9social/perf/<id>`, for example:

    /tmp/9social/perf/12345

A generated performance root should include a marker file named
`.9social-perf-root`. Cleanup scripts use this marker as an extra safety check
before removing a tree.

Scripts should avoid modifying the real user's 9social data under
`$home/lib/9social`.

Some scripts may run commands with simulated users by setting `$home` and `$user`
inside a subprocess. This simulates a user environment for 9social, but it does
not create a real operating-system user.

## Generate Community

`generate-community.rc` creates a posts-only simulated community:

    tests/perf/generate-community.rc small
    tests/perf/generate-community.rc medium
    tests/perf/generate-community.rc large

It creates users named `rms`, `linus`, and `alan`, initializes each user with a
local repository, generates posts, pushes each user once, makes every user follow
the other users, refreshes each user, and prints validation counts.

The final line prints the generated root:

    root: /tmp/9social/perf/<pid>

Generated communities are intentionally left in place. This makes it possible to
rerun measurements, compare code changes against the same data, and browse a
large simulated environment manually. Remove a generated root explicitly with
`clean.rc` when it is no longer needed.

Use that root with `shell-as.rc`, `reindex.rc`, `clean.rc`, and future
performance measurement scripts.

## List Communities

`list.rc` lists generated performance roots:

    tests/perf/list.rc

It only reads under `/tmp/9social/perf`. Marked roots with a config file are
shown in a compact form:

    /tmp/9social/perf/12345  size=medium  posts-per-user=25  users=rms linus alan

Broken or partial roots are labeled instead of failing the whole listing.

## Measure Like

`like.rc` measures one real `9social/cmd/like` operation for a simulated user:

    tests/perf/like.rc /tmp/9social/perf/12345 rms

It assumes the simulated user's index is current before target selection. The
script chooses the first unliked post from another user's feed, prints the target
path and ID, times the `like` command, and leaves the generated root modified for
inspection or follow-up measurements.

## Measure Reply

`reply.rc` measures one real `9social/cmd/reply` operation for a simulated user:

    tests/perf/reply.rc /tmp/9social/perf/12345 rms

The script chooses the first valid post from another user's feed, writes a small
deterministic reply body under the generated root's `logs` directory, prints the
target path and ID, times the `reply` command, and leaves the generated root
modified for inspection or follow-up measurements.


## Measure Index Update

`index-update.rc` measures several `9social/lib/index/update` paths for one simulated user:

    tests/perf/index-update.rc /tmp/9social/perf/12345 rms

It removes that simulated user's existing index, times the initial update, times an
unchanged update after state exists, commits a small batch of self posts and times
the add-only incremental path, then commits one modification and one deletion. The
modification and deletion cases are labeled as fallback rebuilds in the output.

The script mutates only the selected simulated user's home under the generated
perf root. The generated root is left in place for inspection or follow-up
measurements.

## Measure Reindex

`reindex.rc` rebuilds the index for one simulated user and prints timing output:

    tests/perf/reindex.rc /tmp/9social/perf/12345 rms

It runs one `9social/lib/index/rebuild` as that simulated user and then prints
the number of indexed posts. The generated root is left intact.

## Simulated User Shell

`shell-as.rc` starts a command or interactive shell as a simulated user:

    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms
    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms 9social/Menu
    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms acme

The target root must contain:

    homes/<user>/lib/9social

The script binds this repository's `bin` directory before `/bin` in the
subprocess namespace, so the simulated shell uses the working tree version of
9social.

## Interactive Acme Browsing

A generated community can be explored interactively by starting acme as a
simulated user:

    tests/perf/list.rc
    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms acme

The acme process starts with `$home` set to the simulated user's home and
`$user` set to the simulated user name. Inside that acme, run:

    9social/Menu

This opens the normal 9social acme menu against the simulated environment.
`Timeline`, `ShowThreads`, `Like`, and `Reply` have been manually verified with
this workflow.

## Cleanup

`clean.rc` removes a generated performance root:

    tests/perf/clean.rc /tmp/9social/perf/12345

It refuses to remove paths outside `/tmp/9social/perf/`, paths containing `..`,
and roots that do not contain `.9social-perf-root`.
