# 9social — Acme Like Command

## Purpose

Define how a user likes another user's post from Acme.

`Like` is the first concrete reaction command for 9social. Earlier design notes used the word `upvote`, but Level 1 uses `like` because it is short, familiar, and does not imply ranking.

---

## Command

```rc
9social/Like
```

`Like` is an Acme tag command.

Level 1 accepts no arguments. It operates on the current Acme window path, provided by Acme through `$%`.

Invalid arguments print:

```text
usage: 9social/Like
```

and exit with `usage`.

---

## Core Model

A like is an immutable post-like record published in the liking user's own feed.

A like does not modify the target post and is not stored in the target author's repository.

If Glenda likes a post by Dennis:

```text
Glenda publishes a like record in Glenda's feed
→ the like record targets Dennis's post ID
→ other users see the like if they follow Glenda and refresh
```

This keeps likes decentralized, local-first, and owned by the user who issued them.

---

## Like Record Format

A like is stored under the liking user's `self/posts/` directory, just like ordinary posts and replies.

The record has metadata and no body.

Example:

```text
id: 9social:post:f9259502-4dde-484c-94b2-1f226226ba70:4f5b32de-2f02-4f13-bf8c-f0f1a5c7e6a1
author: dharmatech
date: 2026-04-30T12:34:56Z
type: like
target: 9social:post:9acf94aa-8504-4585-b7e5-2ff0b9847fe3:d74aacda-68ee-4d1c-9f83-35e89a956676

```

### Required fields

* `id`
* `author`
* `date`
* `type`
* `target`

### Field meanings

#### type

For likes:

```text
type: like
```

#### target

The canonical ID of the post being liked.

```text
target: 9social:post:<target-user-uuid>:<target-post-uuid>
```

Likes must target post IDs, not local filesystem paths.

---

## Acme Workflow

A typical workflow is:

1. User opens another user's post with `9social/open-post`.
2. The post window tag includes:

```text
9social/Reply 9social/Like
```

3. User middle-clicks `9social/Like`.
4. `Like` reads the target post ID from the current post window.
5. `Like` writes a `type: like` record into the user's `self/posts/` directory.
6. `Like` commits the new like record locally.
7. The user later runs `9social/push` when ready.

`Like` does not push.

---

## Tag Placement

`9social/open-post` should add `9social/Like` when opening posts from followed feeds.

For followed-feed posts:

```text
 | 9social/Reply 9social/Like
```

For self posts:

```text
 | 9social/Reply 9social/Update 9social/Delete
```

Level 1 does not show `Like` on the user's own posts.

---

## Publishing Behavior

Before creating a like record, `Like` should validate:

* `$home/lib/9social/self` exists and is usable, using `bin/9social/lib/check-self`
* `$%` is set
* `$%` names a readable post file
* the target post has a valid `id:` field, using `bin/9social/lib/post-id`

`Like` should generate:

* a new post UUID for the like record
* a UTC timestamp
* a filename under `self/posts/`

The filename only needs to be unique within the user's own `posts/` directory. A reasonable Level 1 form is:

```text
YYYY-MM-DD-like-<short-target-or-counter>
```

The final naming rule can reuse the same collision handling used by `new-post` and `publish-draft`.

The Git commit should include only the new like record, not unrelated dirty files.

Example commit message:

```text
like: 9social:post:<target-user-uuid>:<target-post-uuid>
```

---

## Duplicate Likes

Level 1 may allow duplicate like records from the same author to the same target.

That keeps the initial command simple and avoids needing an index before the record format is proven.

When calculating counts, clients should treat likes as a current-state signal by author and target:

* for each `(author, target)` pair, count at most one current like
* if future unlike records are introduced, the latest event for that pair determines state

A future version may make `Like` idempotent by detecting an existing like before creating a new one.

---

## Counts And Indexing

Like counts are not required for the first `Like` implementation.

The core primitive is the like record itself.

Counts should be derived locally from followed feeds and the user's own feed. Counts are viewer-relative: a user only sees likes from feeds they have locally refreshed.

A future index may map:

```text
<target-post-id> → like records targeting that post
```

This would make post view enrichment efficient.

---

## Post View Display

Level 1 `open-post` should focus on opening the post and exposing actions in the tag.

It should not mutate the displayed post body to add counts yet.

Future post views may show generated context above the post, for example:

```text
likes: 15
replies: 3

id: ...
author: ...
```

This generated context is view data, not part of the stored post file.

---

## Timeline Behavior

Like records should not appear as ordinary posts in the default timeline.

The timeline may use them later to enrich post summaries, but Level 1 should skip `type: like` records in the ordinary timeline view.

---

## Non-Goals

Level 1 does not support:

* displaying like counts
* indexing likes
* unliking a post
* preventing duplicate likes
* pushing after liking
* liking by post ID from the shell
* global like counts

