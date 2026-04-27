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
* Reuse the same post format and validation rules as `9social/new-post`

---

## 3. Relationship To `new-post`

`9social/new-post` is synchronous:

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

---

## 5. Draft Creation

`NewPost` creates a draft file in `$home/tmp` if that directory exists. Otherwise it uses `/tmp`.

Draft filenames should be unique for the command invocation, for example:

```text
9social-new-post.<pid>
```

The draft starts with the same draft format used by `new-post`:

```text
Title: 

```

The user edits this file in Acme.

---

## 6. Opening The Draft In Acme

`NewPost` opens the draft using plumbing, targeting the edit port.

Expected command shape:

```rc
plumb -d edit -w <draft-directory> <draft-path>
```

The user's plumbing rules decide which editor receives the message. In a normal Acme session, the edit port should be handled by Acme.

If plumbing fails, `NewPost` should leave the draft file in place and print its path.

---

## 7. Draft Window Tag

The desired Acme draft window tag should expose commands for post lifecycle actions.

Level 1 target tag commands:

```text
Publish Cancel
```

### Publish

`Publish` commits the draft as a new post locally.

It does not push to the remote repository.

### Cancel

`Cancel` discards the draft without committing.

It should remove the draft file. Closing the Acme window may require a separate Acme action if direct window control is not implemented in Level 1.

---

## 8. Publishing Command

Publishing should be implemented by a separate command that can be invoked from the Acme tag:

```rc
9social/publish-draft <draft-path>
```

`publish-draft` should apply the same rules as `new-post`:

* Validate `$home/lib/9social/self`
* Validate `$home/lib/9social/self/profile`
* Parse the draft
* Generate post ID
* Generate UTC timestamp
* Generate final filename
* Write exactly one final post file without overwriting
* Commit only the new post file
* Do not push
* Remove the draft after successful publish
* Preserve the draft on validation, write, or Git failure

`9social/new-post -` may later call into the same implementation path.

---

## 9. Cancel Command

Cancel should be implemented by a separate command:

```rc
9social/cancel-draft <draft-path>
```

Level 1 behavior:

* Validate that the path looks like a 9social draft path
* Remove the draft file
* Print a confirmation

Possible output:

```text
cancelled: /usr/glenda/tmp/9social-new-post.<pid>
```

Future versions may also ask Acme to close the draft window.

---

## 10. Output

On successful draft creation/opening, `NewPost` should print the draft path:

```text
draft: /usr/glenda/tmp/9social-new-post.<pid>
```

It should also print the commands that can publish or cancel the draft if tag customization is not yet implemented:

```text
publish: 9social/publish-draft /usr/glenda/tmp/9social-new-post.<pid>
cancel: 9social/cancel-draft /usr/glenda/tmp/9social-new-post.<pid>
```

This gives the user a recovery path even if Acme tag injection is deferred.

---

## 11. Failure Handling

If draft creation fails:

* abort
* print the reason to stderr

If plumbing fails:

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

## 12. Non-Goals (Level 1)

Level 1 does not require:

* Direct Acme event-loop integration
* Direct Acme window closing from `Cancel`
* Automatic tag rewriting if plumbing alone is sufficient for initial use
* Remote push after publishing
* Editing existing posts
* Replies or reactions

---

## 13. Open Questions

The main open design question is how much Acme window/tag control Level 1 should implement.

Options:

* Minimal: plumb the draft and print `publish-draft` / `cancel-draft` commands
* Better Acme integration: programmatically set the draft window tag to include `Publish` and `Cancel`
* Full integration: implement an Acme event-driven helper for draft windows

Recommendation for first implementation:

Start with the minimal version, then add tag control after the publishing path is reliable.

---

## 14. Test Strategy

Automated tests should focus on the non-interactive pieces:

* `publish-draft <draft-path>` publishes a valid draft
* `publish-draft` preserves draft on failure
* `cancel-draft <draft-path>` removes a draft
* invalid arguments print usage

Manual Acme tests should verify:

* `9social/NewPost` opens a draft in Acme
* the draft template is correct
* the printed publish command works
* the printed cancel command works
* publishing commits locally but does not push

---

## 15. Summary

`9social/NewPost` is the Acme-native new post workflow.

It creates a draft window and lets the user publish or cancel explicitly from Acme.

This keeps `new-post` simple and synchronous while giving Acme users a workflow that fits Acme's tag-oriented interface.
