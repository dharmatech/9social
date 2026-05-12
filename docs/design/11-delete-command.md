# 9social — Acme Delete Command

## Purpose

Define how a user deletes one of their own 9social posts from Acme.

Deletion is useful for test posts, mistakes, and ordinary cleanup. It should fit the same local-first Git model as `NewPost`, `Publish`, `Reply`, and `push`.

---

## Command

```rc
9social/Delete
```

`Delete` is an Acme tag command.

`Delete` is the Acme wrapper for deleting the current self post. A future command-line core command may expose the same operation without Acme by accepting an explicit self-post path or post ID.

Level 1 accepts no arguments. It operates on the current Acme window path, provided by Acme through `$%`.

Invalid arguments print:

```text
usage: 9social/Delete
```

and exit with `usage`.

---

## Scope

`Delete` may delete only posts in the user's own self repository:

```text
$home/lib/9social/self/posts/<post-file>
```

It must refuse to delete posts from followed feeds, for example:

```text
$home/lib/9social/feeds/<feed>/posts/<post-file>
```

This prevents accidentally deleting local cached copies of other people's posts and keeps feed refresh behavior simple.

---

## Acme Workflow

A typical workflow is:

1. User opens their own post with `9social/OpenPost`.
2. The post window tag includes:

```text
9social/Reply 9social/Update 9social/Delete
```

3. User middle-clicks `9social/Delete`.
4. `Delete` removes the backing post file from `self/posts/`.
5. `Delete` commits the removal locally.
6. The user later runs `9social/push` when ready.

`Delete` does not push.

`Delete` does not close the Acme window. On success it should print a message such as:

```text
deleted: posts/<post-file>
close the Acme window with Del
```

The user remains in control of the Acme window lifecycle.

---

## Validation

Before deleting, `Delete` should validate:

* `$home/lib/9social/self` exists and is usable, using `bin/9social/lib/check-self`
* `$%` is set
* `$%` names a regular file under `$home/lib/9social/self/posts/`
* the file has a valid `id:` field, using `bin/9social/lib/post/id.awk`

If any check fails, `Delete` should fail without removing the file.

---

## Git Behavior

Deletion is local-first.

`Delete` should remove and commit only the current post file. It must not commit unrelated dirty files in `self/`.

The commit message should include the post ID, for example:

```text
delete post: 9social:post:<user-uuid>:<post-uuid>
```

The exact 9front Git command sequence should follow the `git(1)` man page. The key requirement is that the commit names only the deleted post path relative to `self/`, such as:

```text
posts/2026-04-29-test-post
```

---

## Tag Placement

`9social/OpenPost` should add `9social/Delete` only when opening a post from the user's own self repository.

For self posts:

```text
 | 9social/Reply 9social/Update 9social/Delete
```

For followed-feed posts:

```text
 | 9social/Reply
```

This keeps delete available where it is valid without presenting it for posts the user does not own.

---

## Confirmation

Level 1 does not require an interactive confirmation prompt.

The safety boundary is:

* `Delete` only accepts the current Acme window path
* the path must be under `self/posts/`
* the file must parse as a 9social post
* the operation is committed in Git, so it can be inspected or reverted later

A future version may add a confirmation workflow if accidental deletion becomes a practical problem.

---

## Non-Goals

Level 1 does not support:

* deleting posts from followed feeds
* deleting by post ID
* deleting from `timeline` directly
* pushing after deletion
* tombstone records
* federated delete propagation

A deleted post is simply absent from the user's repository after the deletion commit.

---

## Relationship To Replies

Deleting a post does not delete replies to that post.

Replies are independent posts owned by their authors. If a post is deleted, replies that target its post ID may become replies to a post the local client can no longer display.

Thread views should tolerate missing targets.
