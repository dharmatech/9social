# 9social — Like Commands

## Purpose

Define how a user likes another user's post from the command line and from Acme.

`Like` is the first concrete reaction command for 9social. Earlier design notes used the word `upvote`, but Level 1 uses `like` because it is short, familiar, and does not imply ranking.

---

## Commands

### Command-line core

```rc
9social/cmd/like <post-ref>
```

`like` is the non-interactive core command. It accepts an explicit local post file path, creates a like record in the current user's `self/posts/`, commits it locally, and rebuilds the local index.

It does not require Acme. This command is suitable for terminal workflows and automated tests.

Invalid arguments print:

```text
usage: 9social/cmd/like <post-ref>
```

and exit with `usage`.

### Acme wrapper

```rc
9social/Post/Like
```

`Like` is an Acme tag command and thin wrapper around `like`. It accepts no arguments, reads the current Acme window path from `$%`, and delegates to:

```rc
9social/cmd/like $%
```

Invalid arguments print:

```text
usage: 9social/Post/Like
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

1. User opens another user's post with `9social/OpenPost`.
2. The post window tag includes:

```text
9social/Post/Reply 9social/Post/Like
```

3. User middle-clicks `9social/Post/Like`.
4. `Like` delegates to `9social/cmd/like $%`.
5. `like` reads the target post ID from the current post file.
6. `like` writes a `type: like` record into the user's `self/posts/` directory.
7. `like` commits the new like record locally.
8. The user later runs `9social/cmd/push` when ready.

`like` does not push. `Like` also does not push because it delegates to `like`.

---

## Tag Placement

`9social/OpenPost` should add `9social/Post/Like` when opening posts from followed feeds if the local index does not show that the current user has already liked the post.

If the index is missing or unreadable, `OpenPost` should prefer showing `9social/Post/Like` rather than rebuilding the index during post opening. `Like` itself remains responsible for enforcing idempotence before publishing.

If the local index shows that the current user has already liked the post, Level 1 should omit `9social/Post/Like` from the tag. `9social/Unlike` can be considered later.

For followed-feed posts:

```text
 | 9social/Post/Reply 9social/Post/Like
```

For self posts:

```text
 | 9social/Post/Reply 9social/Post/Update 9social/Post/Delete
```

Level 1 does not show `Like` on the user's own posts.

---

## Publishing Behavior

Before creating a like record, `like` should validate:

* `$home/lib/9social/self` exists and is usable, using `bin/9social/lib/check-self`
* the explicit `<post-file>` names a readable post file
* the target post has a valid `id:` field, using `bin/9social/lib/post/id.awk`
* the target post is not under `$home/lib/9social/self/posts/`

`like` should generate:

* a new post UUID for the like record
* a UTC timestamp
* a filename under `self/posts/`

The filename only needs to be unique within the user's own `posts/` directory. Level 1 should use:

```text
YYYY-MM-DD-like-<n>
```

where `<n>` is omitted for the first available filename or incremented using the same collision handling style used by `new-post` and `publish-draft`.

The Git commit should include only the new like record, not unrelated dirty files.

Example commit message:

```text
like: 9social:post:<target-user-uuid>:<target-post-uuid>
```

---

## Duplicate Likes

Once the local index exists, `like` should be idempotent.

Before creating a like record, `like` should check the index for existing likes targeting the current post. It should read those like record files and check whether any valid like was authored by the current user.

The current user should be identified by reading `name:` from `$home/lib/9social/self/profile` and comparing it to the like record `author:` field. This matches the existing authorship model for ordinary posts and replies.

This check should live in a reusable helper such as:

```rc
9social/lib/liked-post <post-id>
```

The helper should use `$home/lib/9social/index/targets/<encoded-target>/likes`, `post-meta`, and the current profile name. It should exit successfully if the current user has already liked the target post, and nonzero otherwise. `OpenPost` can use this helper to decide whether to show `9social/Post/Like`; `like` can use it to enforce idempotence.

If the current user has already liked the target post, `like` should print a short message such as:

```text
already liked
```

and exit successfully without creating a new like record or Git commit.

If no current-user like exists, `like` creates one `type: like` record and commits it locally.

After a successful commit, `like` should run `9social/lib/index/rebuild` so subsequent `OpenPost` calls can immediately omit `9social/Post/Like` for that target.

On success, `like` should print:

```text
liked: <target-post-id>
posted: posts/<like-file>
```

`like` does not push. `Like` also does not push because it delegates to `like`.

If the index is missing or stale, `like` may run `9social/lib/index/rebuild` first and then check again. Future latency improvements are discussed in `17-local-action-latency.md`, including commit-now-index-later and local outbox approaches.

Historical duplicate like records may still exist. `reindex` should tolerate them. When calculating counts, clients should treat likes as a current-state signal by author and target:

* for each `(author, target)` pair, count at most one current like
* if future unlike records are introduced, the latest event for that pair determines state

---

## Counts And Indexing

Like counts are not required for the first `like` implementation or the first index implementation.

The core primitive is the like record itself.

Counts should be derived locally from followed feeds and the user's own feed. Counts are viewer-relative: a user only sees likes from feeds they have locally refreshed.

The Level 1 local index is defined in `14-index.md`.

Likes are indexed under:

```text
$home/lib/9social/index/targets/<encoded-target>/likes/<encoded-like-id>
```

Each leaf file contains the local path to the like record file.

This makes post view enrichment efficient without changing the stored post format. Count/display helpers should be implemented after the core index primitives are working.

---

## Post View Display

Level 1 `OpenPost` should focus on opening the post and exposing actions in the tag.

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
* implementing `Unlike`
* pushing after liking
* liking by post ID from the shell
* global like counts


---

## Future Unlike Model

The Level 1 like design is compatible with a future `9social/Unlike` command.

`Unlike` should create a new immutable reaction record rather than deleting the original like record.

A future unlike record may look like:

```text
id: 9social:post:<self-user-uuid>:<unlike-post-uuid>
author: dharmatech
date: 2026-05-04T12:34:56Z
type: unlike
target: 9social:post:<target-user-uuid>:<target-post-uuid>

```

This allows a user to perform a sequence such as:

```text
Like, Unlike, Like, Unlike
```

without mutating or deleting old records.

When `Unlike` exists, clients should calculate current like state per `(author, target)` pair by sorting that author's like/unlike records for the target by `date:` and taking the latest valid event.

Until `Unlike` exists, Level 1 treats any valid like by the current user for a target as meaning the post is already liked.
