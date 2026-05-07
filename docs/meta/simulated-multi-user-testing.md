# Simulated Multi-User Testing

This note describes a testing approach for exercising 9social's multi-user behavior without requiring multiple real Plan 9 accounts or remote hosting services.

## Goal

9social is social software, so important behavior crosses user boundaries:

* one user creates posts
* another user follows and refreshes
* another user replies
* another user likes
* timelines and thread views reflect the combined local data

The default automated tests should be able to cover this logic without depending on GitHub, SSH keys, network access, or live Acme sessions.

## Simulated Users

A simulated user is a test directory with its own `$home`.

Example:

```text
/tmp/9social/workflow/
    homes/
        alice/
        bob/
        carol/
    remotes/
        alice/
        bob/
        carol/
```

Each simulated home has its own 9social runtime tree:

```text
/tmp/9social/workflow/homes/alice/lib/9social/
    self/
    feeds/
    index/
```

Tests run commands with `home` set to the simulated user's home:

```rc
home=$root/homes/alice 9social/new-post -t 'hello' < $body
home=$root/homes/bob 9social/refresh
```

Setting `user` as well can make test output clearer:

```rc
home=$root/homes/alice user=alice 9social/new-post -t 'hello' < $body
```

However, 9social identity should come from `$home/lib/9social/self/profile`, not from `$user`.

## Local Repositories

Remote repositories are simulated with local Git repositories under the test root.

Each simulated remote starts as an ordinary repository created with `git/init`. A temporary seed repository creates an initial README commit and pushes it into the remote before the simulated user runs `init-self`. This preserves the 9front `git/clone` requirement that the repository not be empty.

This lets tests exercise real `git/clone`, `git/pull`, `git/push`, `follow`, `refresh`, and `reindex` behavior without talking to a network service.

The workflow should initialize one local self repository per simulated user, then use the local repository paths in `following` files.

## Helper Shape

A workflow test can define a small helper:

```rc
fn asuser {
	u=$1
	shift
	home=$root/homes/$u user=$u $*
}
```

Then the test can read like a user story:

```rc
asuser alice 9social/new-post -t 'hello' < $body
asuser alice 9social/push

asuser bob 9social/follow $root/remotes/alice
asuser bob 9social/refresh
asuser bob 9social/timeline
```

## Verbose Walkthrough

The workflow test supports a verbose mode:

```rc
tests/workflow.rc -v
```

Verbose mode keeps the same assertions but prints a play-by-play of the simulated users, commands, command output, and selected artifacts such as profiles, following files, created posts, and timeline output.

The default mode remains quiet so `tests/run.rc` can use it as an ordinary regression test.

## What This Tests

This approach tests the 9social data model and command composition:

* post creation
* local Git commits
* pushing to a local remote
* following another feed
* refreshing followed feeds
* timeline rendering
* index rebuilding
* post lookup
* replies
* likes
* updates and deletes

It also exposes commands that are not yet non-interactive-ready.
If a command cannot participate in this workflow without Acme, that is a useful design signal.

## What This Does Not Test

Simulated users do not test Plan 9 account/session behavior.

They do not verify:

* real uid changes
* real login sessions
* real per-user namespaces
* Acme window behavior
* plumber behavior
* SSH authentication to remote hosting services

Those belong in optional integration tests or manual smoke tests.

## Real Multi-User Integration Tests

For later, a separate optional test can use real Plan 9 users with `auth/as`:

```rc
auth/as socialtest1 rc -c '9social/new-post ...'
auth/as socialtest2 rc -c '9social/refresh'
```

This should not be part of the default test suite because it depends on pre-created users and hostowner privileges.

## Recommendation

Use simulated users and local repositories for the default non-interactive multi-user workflow test.

Keep real-user testing with `auth/as` as a separate optional integration test.
