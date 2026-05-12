# 9social — Acme NewPost Command (Level 1)

## 1. Overview

This document defines an Acme-native workflow for creating a new 9social post.

The synchronous shell command is defined separately in:

```text
docs/design/06-new-post-command.md
```

This document covers the Acme command:

```rc
9social/NewPost
```

`NewPost` is designed for Acme's command/tag model. It creates a draft window now. Publishing happens later from that draft window.

---

## 2. Goals

* Fit naturally into Acme
* Avoid launching graphical editors from Acme command execution
* Make the draft a normal editable Acme file
* Make publishing an explicit user action
* Keep publishing local-first: commit locally, do not push
* Reuse the same post format and validation rules as `9social/cmd/new-post`

---

## 3. Relationship To `new-post`

`9social/cmd/new-post` is synchronous:

```text
create draft -> edit -> publish -> commit -> exit
```

`9social/NewPost` is asynchronous and Acme-native:

```text
create draft -> open Acme window -> user edits -> user publishes from tag
```

Both workflows should produce the same final post format.

The publishing logic should be shared where practical so the two commands do not diverge.

---

## 4. Command Interface

Primary command:

```rc
9social/NewPost
```

Level 1 accepts no arguments.

Invalid arguments print:

```text
usage: 9social/NewPost
```

and exit with `usage`.

`NewPost` is an Acme-only command in Level 1. It requires the Acme filesystem at:

```text
/mnt/wsys/index
```

`NewPost` should check for `/mnt/wsys/index`, not `/mnt/wsys/new/ctl`. In Acme, accessing files under `/mnt/wsys/new` creates a new window, while `index` is a non-creating availability check.

If `/mnt/wsys/index` is missing or inaccessible, `NewPost` should fail before creating a draft. It should not silently fall back to `9social/cmd/new-post`, because the synchronous editor workflow is a separate command.

Recommended error text:

```text
NewPost: acme window system not available
NewPost: run from acme, or use 9social/cmd/new-post
```

---

### Naming Convention

9social uses command names to distinguish shell workflows from Acme tag workflows:

* lowercase hyphenated names are shell/terminal commands, such as `9social/cmd/new-post` and `9social/cmd/init-self`
* capitalized names are Acme tag commands, such as `9social/NewPost`, `9social/Draft/Publish`, and `9social/Draft/Cancel`

Level 1 does not provide lowercase aliases for Acme commands or uppercase aliases for shell commands.

---

## 5. NewPost Preflight Validation

Before creating a draft file or Acme window, `NewPost` should use `bin/9social/lib/check-self` to verify that the user's publishing feed is basically usable:

* `$home/lib/9social/self` exists
* `$home/lib/9social/self` is a Git repository
* `$home/lib/9social/self/profile` exists
* `profile` has valid `id:`, `name:`, and `display:` fields
* `$home/lib/9social/self/posts` exists, creating it if missing

`NewPost` should not validate draft content at this point because the user has not written the post yet. Content validation happens at publish time.

`Publish` must repeat feed and profile validation before committing because the repository or profile may have changed while the draft window was open.

---

## 6. Draft Creation

`NewPost` should prefer `$home/tmp` for draft files. If `$home/tmp` does not exist, `NewPost` should try to create it. It should fall back to `/tmp` only if `$home/tmp` cannot be created or used.

Draft filenames should be unique for the command invocation. The preferred filename is:

```text
9social-new-post.<pid>
```

`NewPost` must not overwrite an existing draft file. If the preferred path already exists, it should choose the next available suffixed name:

```text
9social-new-post.<pid>.2
9social-new-post.<pid>.3
```

The selected draft path must be checked immediately before writing.

Draft paths created by `NewPost` are the only paths that `Publish` and `Cancel` should operate on in Level 1. A valid draft path is:

* under `$home/tmp`, creating that directory if possible, or under `/tmp` if `$home/tmp` cannot be created or used
* named `9social-new-post.<pid>` or `9social-new-post.<pid>.<n>` for collision suffixes

This keeps pathless Acme tag commands ergonomic without letting them publish or delete an arbitrary current Acme file by accident.

The draft starts with the same draft format used by `new-post`:

```text
Title: 

```

`NewPost` writes this template, including the blank line after `Title:`, to the backing draft file before creating the Acme window.

The user edits this file in Acme.

---

## 7. Opening The Draft In Acme

Level 1 `NewPost` creates an Acme window directly through Acme's filesystem interface.

It should use `/mnt/wsys`, which is bound to `/mnt/acme` for commands running under Acme.

The Acme window creation mechanics should live in a shared helper, for example:

```text
bin/9social/lib/open-draft-window
```

`NewPost` and future draft-producing Acme commands such as `Reply` should both use this helper instead of copying the Acme filesystem logic.

Expected helper interface:

```rc
9social/lib/open-draft-window <draft-path>
```

Expected mechanism:

```text
require /mnt/wsys/index
open /mnt/wsys/new/ctl
read new window id from ctl
write name <draft-path> to ctl
write get to ctl so Acme loads the backing file as a normal file window
write tag text to /mnt/wsys/<id>/tag
write clean to ctl
```

The caller is responsible for creating the backing draft file before invoking the helper. The Acme window body and backing file should match immediately after creation.

The helper should load the body with Acme `get`, not by writing the template directly to `/mnt/wsys/<id>/body`. Loading with `get` makes later `Put` from `9social/Draft/Publish` behave like ordinary file-window saving. Direct body writes can make Acme refuse `Put` with a "file already exists" error.

After loading the initial template, the helper should mark the window clean by writing:

```text
clean
```

to the window `ctl` file. The window should become dirty only after the user edits it.

This mirrors the basic window creation approach used by Acme applications such as `Mail`, without requiring a long-running event loop.

If direct Acme window creation fails, the helper should leave the draft file in place and print its path. The caller may add command-specific error context.

Plumbing may remain a fallback or future option, but it is not the primary Level 1 mechanism.

---

## 8. Draft Window Tag

The Acme draft window tag should expose commands for post lifecycle actions.

Level 1 should let Acme manage the left side of the tag for the draft file window. This keeps normal file-window commands such as `Put` available.

`NewPost` should add 9social commands after the tag bar. Since writing to the tag appends, the implementation should append:

```text
 | 9social/Draft/Publish 9social/Draft/Cancel
```

The full tag may look like:

```text
<draft-path> Del Snarf Undo Put | 9social/Draft/Publish 9social/Draft/Cancel
```

The exact left side is managed by Acme and does not need to be controlled by 9social.

Level 1 should not add decorative or status text to the right side of the tag. The appended text should contain only the two command words shown above: no `draft` marker, no `9social` label, no `NewPost` label, and no draft path argument. Extra tag words are executable text in Acme and can make the workflow noisier.

Pathless commands are better Acme ergonomics than including the full draft path in the tag. The user can middle-click a single command word without first selecting a long command string.

### Publish

`9social/Draft/Publish` commits the current draft as a new post locally.

It does not push to the remote repository.

When run from Acme, `Publish` discovers the draft from Acme-provided environment:

* `$%` is the current Acme window filename
* `$winid` is the current Acme window id

Level 1 `Publish` should use `$%` as the draft path.

Before saving or publishing, `Publish` should validate that `$%` names a 9social draft path created by `NewPost`, using `bin/9social/lib/valid-draft`. If it does not, it should fail with a clear message and leave the file untouched.

If `$winid` is available and `/mnt/acme/$winid/ctl` exists, `Publish` should first save the current Acme window by writing `put` to:

```text
/mnt/acme/$winid/ctl
```

If this save step fails, `Publish` must abort. Publishing after a failed save could publish stale file contents.

If `$winid` is missing, `Publish` skips the save step and reads `$%` from disk. This keeps the command testable outside Acme by setting `$%` to a draft path.

Then it reads the draft from `$%` on disk and publishes it. After a successful publish, `Publish` removes the backing draft file, leaves the Acme window open, and does not rewrite the tag. The user closes the draft window with Acme's `Del` command. If the user runs `Publish` again from the same window, the missing backing draft file should produce a clear failure rather than creating another post.

### Cancel

`9social/Draft/Cancel` discards the current draft without committing.

When run from Acme, `Cancel` discovers the draft from `$%`.

Before removing anything, `Cancel` should validate that `$%` names a 9social draft path created by `NewPost`, using `bin/9social/lib/valid-draft`. If it does not, it should fail with a clear message and leave the file untouched.

Level 1 `Cancel` removes the backing draft file and prints a confirmation. It does not close the Acme window automatically. The user closes the draft window with Acme's `Del` command.

---

## 9. Publishing Command

Publishing should be implemented by a separate command that can be invoked from the Acme tag:

```rc
9social/Draft/Publish
```

When run from Acme, `Publish` uses `$%` as the draft path. It should fail if `$%` is missing or empty.

It should also fail if `$%` does not look like a 9social draft path created by `NewPost`.

If `$winid` is set, `Publish` should try to save the Acme window before reading `$%`. If that save fails, abort.

`Publish` should apply the same rules as `new-post`:

* Validate `$home/lib/9social/self`
* Validate `$home/lib/9social/self/profile`
* Repeat feed and profile validation even though `NewPost` already ran preflight checks
* Parse the draft
* Generate post ID
* Generate UTC timestamp
* Generate final filename
* Write exactly one final post file without overwriting
* Commit only the new post file
* Do not push
* Remove the backing draft file after successful publish
* Leave the Acme window open after successful publish; the user closes it with `Del`
* Preserve the draft on validation, write, or Git failure
* Do not rewrite the Acme tag after successful publish
* If `$%` no longer exists because the draft was already published, fail clearly
* Accept both `9social-new-post.<pid>` and suffixed `9social-new-post.<pid>.<n>` draft filenames

The shared publish path should live in an internal helper script:

```text
bin/9social/lib/publish-draft
```

The helper publishes one draft file passed by path. It owns the common behavior: profile validation, draft parsing, post ID generation, timestamp generation, filename selection, final post writing, Git add/commit, success output, draft cleanup on success, and draft preservation on failure.

`9social/cmd/new-post` and `9social/Draft/Publish` should both call this helper instead of duplicating publish logic. `new-post` is responsible for creating/editing or reading the draft before calling the helper. `Publish` is responsible for discovering `$%` from Acme, validating that it is a `NewPost` draft path, and saving the Acme window before calling the helper.

The helper is internal implementation detail, not a Level 1 user command.

---

## 10. Cancel Command

Cancel should be implemented by a separate command:

```rc
9social/Draft/Cancel
```

When run from Acme, `Cancel` uses `$%` as the draft path. It should fail if `$%` is missing or empty.

Level 1 behavior:

* Validate that the path looks like a 9social draft path, including optional collision suffixes
* Remove the draft file
* Print a confirmation
* Leave the Acme window open; the user closes it with `Del`

Possible output:

```text
cancelled: /usr/glenda/tmp/9social-new-post.<pid>
```

A future version may also ask Acme to close the draft window using `$winid`, after the exact `ctl` behavior has been tested.

---

## 11. Output

On successful draft creation/opening, `NewPost` should not print anything. Under Acme, command output appears in a `+Errors` window, so successful output would create a distracting extra window.

If Acme window creation or tag setup fails after the backing draft file has been created, `NewPost` should print the draft path as part of the error path. This gives the user a recovery path only when recovery is needed.

On successful publish, `Publish` should print the stable `posted:` line from the shared publish helper, followed by a short Acme-specific reminder:

```text
posted: posts/2026-04-27-my-post
draft removed; close the Acme window with Del
```

If `Publish` is run again from a window whose backing draft was already removed, it should fail clearly:

```text
Publish: draft file not found: /usr/glenda/tmp/9social-new-post.<pid>
```

---

## 12. Failure Handling

If the Acme window system is unavailable:

* abort before creating a draft
* print a clear message suggesting `9social/cmd/new-post` for the synchronous workflow

If preflight validation fails:

* abort before creating a draft
* print the reason to stderr

If `$home/tmp` cannot be created or used:

* fall back to `/tmp`
* if `/tmp` also cannot be used, abort before creating a draft

If draft creation fails:

* abort
* print the reason to stderr

If Acme window creation fails:

* leave the draft file in place
* print the reason to stderr
* print the draft path

If publishing fails:

* leave the draft file in place
* print the reason to stderr
* do not delete the draft automatically

If cancelling fails:

* print the reason to stderr
* leave the draft file in place

---

## 13. Non-Goals (Level 1)

Level 1 does not require:

* Direct Acme event-loop integration
* Automatic Acme window closing from `Publish` or `Cancel`
* Bare non-namespaced `Publish` / `Cancel` commands handled by an event loop
* Rewriting the Acme tag after successful publish
* Decorative tag labels or status markers such as `draft`
* Fallback to `9social/cmd/new-post` when Acme is unavailable
* Remote push after publishing
* Editing existing posts
* Replies or reactions

---

## 14. Open Questions

The main open design question is how much Acme window/tag control Level 1 should implement.

Options:

* Minimal: create the Acme window directly and put `9social/Draft/Publish` / `9social/Draft/Cancel` in the tag
* Better Acme integration: have `Publish` save the window automatically through `$winid` before reading `$%`
* Full integration: implement an Acme event-driven helper for draft windows that handles bare non-namespaced `Publish` and `Cancel`

Recommendation for first implementation:

Start with direct window creation plus `9social/Draft/Publish` and `9social/Draft/Cancel` in the tag. Consider an event-loop helper only if the workflow needs bare non-namespaced `Publish` and `Cancel` commands.

---

## 15. Test Strategy

The durable regression tests live in:

```rc
tests/run.rc
```

Run them from 9front with:

```rc
/usr/glenda/src/9social/tests/run.rc
```

Automated tests should focus on the filesystem and publishing pieces that do not require a live Acme session:

* `bin/9social/lib/check-self` validates the self feed and creates `posts/` when missing
* `bin/9social/lib/valid-draft` accepts valid draft paths and rejects invalid ones
* `9social/Draft/Publish` publishes the draft named by `$%` when `$winid` is unset
* `9social/Draft/Publish` rejects invalid `$%` paths
* `9social/Draft/Publish` fails clearly when `$%` names a missing draft file
* `9social/Draft/Publish` preserves the draft on validation, write, or Git failure
* `9social/Draft/Cancel` removes the draft named by `$%`
* `9social/Draft/Cancel` rejects invalid `$%` paths
* `bin/9social/lib/publish-draft` is exercised through both `9social/cmd/new-post -` and `9social/Draft/Publish`
* invalid arguments print usage

Automated tests may also cover `$winid` save behavior when a real Acme window control file is available, but Level 1 should not depend on a mock of `/mnt/wsys`. The Acme filesystem behavior is specific enough that a mock can give false confidence.

Manual Acme smoke tests should verify:

* `9social/NewPost` creates a draft window in Acme
* the draft template is correct
* the tag contains exactly `9social/Draft/Publish 9social/Draft/Cancel` on the right side
* `9social/Draft/Publish` in the tag saves through `$winid` before publishing
* successful publish commits locally, does not push, removes the backing draft file, and leaves the Acme window open
* `9social/Draft/Cancel` removes the backing draft file and leaves the Acme window open

---

## 16. Summary

`9social/NewPost` is the Acme-native new post workflow.

It creates a draft window and lets the user publish or cancel explicitly from Acme.

This keeps `new-post` simple and synchronous while giving Acme users a workflow that fits Acme's tag-oriented interface.
