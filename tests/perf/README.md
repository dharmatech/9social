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

## Measure Reindex

`reindex.rc` rebuilds the index for one simulated user and prints timing output:

    tests/perf/reindex.rc /tmp/9social/perf/12345 rms

It runs one `9social/lib/index/rebuild` as that simulated user and then prints
the number of indexed posts. The generated root is left intact.

## Simulated User Shell

`shell-as.rc` starts a command or interactive shell as a simulated user:

    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms
    tests/perf/shell-as.rc /tmp/9social/perf/12345 rms 9social/Menu

The target root must contain:

    homes/<user>/lib/9social

The script binds this repository's `bin` directory before `/bin` in the
subprocess namespace, so the simulated shell uses the working tree version of
9social.

## Cleanup

`clean.rc` removes a generated performance root:

    tests/perf/clean.rc /tmp/9social/perf/12345

It refuses to remove paths outside `/tmp/9social/perf/`, paths containing `..`,
and roots that do not contain `.9social-perf-root`.
