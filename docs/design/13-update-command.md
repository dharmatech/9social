# 9social — Acme Update Command

## Purpose

Define how a user updates one of their own existing 9social posts from Acme.

`Update` is for ordinary post edits: fixing typos, changing title/body text, or adjusting metadata while preserving a valid post file. It saves the Acme buffer to the backing file and commits that file locally.

---

## Command

```rc
9social/Post/Update
```

`Update` is an Acme tag command.

`Update` is the Acme wrapper for saving and committing the current self-post window. A future command-line core command may expose the commit and validation operation without Acme by accepting an explicit self-post path.

Level 1 accepts no arguments. It operates on the current Acme window path, provided by Acme through `$%`.

Invalid arguments print:

```text
usage: 9social/Post/Update
```

and exit with `usage`.

---

## Scope

`Update` may update only posts in the user's own self repository:

```text
$home/lib/9social/self/posts/<post-file>
```

It must refuse followed-feed posts, such as:

```text
$home/lib/9social/feeds/<feed>/posts/<post-file>
```

A user edits other people's posts by replying, not by changing local cached feed copies.

---

## Acme Workflow

A typical workflow is:

1. User opens their own post with `9social/OpenPost`.
2. The post window tag includes:

```text
9social/Post/Reply 9social/Post/Update 9social/Post/Delete
```

3. User edits the post window.
4. User middle-clicks `9social/Post/Update`.
5. `Update` saves the Acme buffer to the backing file.
6. `Update` validates the saved post file.
7. `Update` commits only that post file locally.
8. The user later runs `9social/push` when ready.

`Update` does not push.

---

## Saving The Acme Buffer

Before validating or committing, `Update` should save the current Acme window by writing `put` to the current window `ctl` file.

This mirrors `Publish`: the command acts on the user's current Acme buffer, not merely the last version written by a manual `Put`.

If the save fails, `Update` must fail without committing.

---

## Validation

Before committing, `Update` should validate:

* `$home/lib/9social/self` exists and is usable, using `bin/9social/lib/check-self`
* `$%` is set
* `$%` names a regular file under `$home/lib/9social/self/posts/`
* the file has a valid post header/body split
* the file has a valid `id:` field, using the canonical `9social:post:<user-uuid>:<post-uuid>` format
* the file has an `author:` field
* the file has a valid UTC `date:` field in Level 1 format: `YYYY-MM-DDThh:mm:ssZ`
* `title:` is optional and may be empty

For Level 1, `Update` may allow metadata edits, including changed `date:` or `author:`, as long as the final file remains valid.

A future version may enforce stronger identity rules, such as rejecting changes to the original `id:`.

---

## Shared Validation Helper

The post validation logic should live in a helper, for example:

```text
bin/9social/lib/post/check.awk
```

Expected helper interface:

```rc
9social/lib/post/check.awk <post-file>
```

The helper should validate ordinary posts and post-like records at the file-format level. `Update` can then combine `check-post` with its own self-post path restriction.

---

## Git Behavior

Update is local-first.

`Update` should commit only the current post file. It must not commit unrelated dirty files in `self/`.

The commit message should include the post ID, for example:

```text
update post: 9social:post:<user-uuid>:<post-uuid>
```

The 9front Git command sequence should be:

```rc
git/add posts/<post-file>
git/commit -m 'update post: <post-id>' posts/<post-file>
```

---

## No-Op Updates

If saving the Acme buffer leaves no Git diff for the current post file, `Update` should exit successfully without creating a commit.

Suggested output:

```text
no changes: posts/<post-file>
```

This lets users middle-click `Update` safely even if they already saved or did not change the file.

---

## Output

On successful commit:

```text
updated: posts/<post-file>
```

On no-op:

```text
no changes: posts/<post-file>
```

Failures should be short diagnostics on stderr.

---

## Tag Placement

`9social/OpenPost` should add `9social/Post/Update` only when opening a post from the user's own self repository.

For self posts:

```text
 | 9social/Post/Reply 9social/Post/Update 9social/Post/Delete
```

For followed-feed posts:

```text
 | 9social/Post/Reply
```

If `Like` is implemented for followed-feed posts, followed-feed posts may later show:

```text
 | 9social/Post/Reply 9social/Post/Like
```

---

## Non-Goals

Level 1 does not support:

* updating followed-feed posts
* pushing after update
* interactive edit prompts
* preserving or comparing the original `id:` before edit
* separate archive/import workflows for backdated posts
* conflict resolution with remote changes

