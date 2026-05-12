# Relocation Refactor Plan

This plan removes command relocation support from the production scripts.

The installed 9social workflow expects users to bind the repository's `bin` directory so commands are available as `9social/...`. Production scripts should therefore call helpers directly, for example `9social/lib/check-self`, instead of deriving helper paths from `$0` with `sed`.

## Goal

Use explicit command paths throughout production scripts:

```rc
9social/lib/check-self
9social/reindex
9social/uuid
```

Avoid this pattern in production scripts:

```rc
helper=9social/lib/helper
if(~ $0 */Command)
	helper=`{echo $0 | sed 's;/Command$;/lib/helper;'}
```

## Why

* The code is easier to read.
* The command being run is visible at the call site.
* Tests should model the real installation environment with `bind`, instead of requiring production scripts to support copied or relocated execution.

## Testing Strategy

Before starting, run the full suite:

```rc
cd /usr/glenda/src/9social
tests/run.rc
```

`tests/run.rc` should normalize the repository path and bind the repo's `bin` directory into `/bin`:

```rc
repo=`{echo $0 | sed 's;/tests/[^/]*$;;'}
repo=`{cd $repo && pwd}
bind -b $repo/bin /bin || fail bind
```

Most tests can then execute commands exactly as users do, with paths such as `9social/Like` and `9social/lib/post/id.awk`.

For tests that need fake helper commands, use bind layering instead of copied script relocation:

```rc
bind -b $testhome/bin /bin || fail bind-fake
bind -a $repo/bin /bin || fail bind-repo
```

The fake helper directory should be bound before the real repo bin, so fake helpers win while all other `9social/...` commands still resolve to the repo.

## Refactor Order

### 1. Low-risk production scripts

Start with scripts where helper calls are straightforward:

* `bin/9social/refresh`
* `bin/9social/init-self`
* `bin/9social/new-post`
* `bin/9social/Cancel`
* `bin/9social/push`
* `bin/9social/Timeline`
* `bin/9social/Menu`
* `bin/9social/lib/publish-draft`
* `bin/9social/lib/acme/current-line`
* `bin/9social/lib/post-path`
* `bin/9social/lib/liked-post`
* `bin/9social/reindex`

Run the closest focused tests after each small group.

### 2. Higher-risk command scripts

Then handle commands with more branching, index behavior, or Acme behavior:

* `bin/9social/Reply`
* `bin/9social/Like`
* `bin/9social/Delete`
* `bin/9social/Update`
* `bin/9social/OpenPost`

`OpenPost` should be refactored carefully because it currently resolves several helpers from multiple branches.

### 3. Tests that likely need adjustment

Most tests should keep direct `$repo/bin/...` command variables if useful, but tests that depended on relocated copied scripts should be changed to use bind-based fake helper namespaces.

Pay special attention to:

* `tests/Menu.rc`
* `tests/OpenPost.rc`

Other focused tests should be run as their corresponding scripts are changed.

## Verification

After all edits, run:

```rc
tests/run.rc
```

Then check that production scripts no longer contain relocation logic:

```rc
grep -n 'echo \$0 | sed' bin/9social/* bin/9social/lib/*
grep -n 'if(~ \$0 \*/' bin/9social/* bin/9social/lib/*
```

Some tests may still use `$0` to find the repository root. That is acceptable; the refactor target is production command relocation, not test harness path discovery.

## Manual Smoke Tests

After the automated suite passes, manually smoke test the Acme-facing commands that were touched:

* `9social/NewPost`
* `9social/Reply`
* `9social/Timeline`
* `9social/ShowThreads`
* `9social/OpenPost`
* `9social/Like`
* `9social/Delete`
* `9social/Update`
