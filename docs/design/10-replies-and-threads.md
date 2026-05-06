
# 9social — Replies and Threads

## Purpose

Define how replies are represented in 9social and how clients may construct thread views from them.

Replies are not part of Level 1 implementation, but the design affects foundational decisions such as:

- stable post IDs
- future indexing
- post selection/opening behavior
- timeline and post-view conventions

---

## Core Principle

> A reply is represented as a normal post with metadata pointing to another post.

Replies are not a separate transport mechanism and do not require a centralized thread store.

They are published in the replying user’s own feed.

---

## Basic Model

If Dennis replies to one of Joe Ossanna’s posts, the reply is stored in Dennis’s feed as a post file.

That reply includes metadata identifying the target post.

Example conceptually:

```text
Dennis publishes reply in Dennis's feed
→ reply points to Joe's post ID
→ clients reconstruct thread relationships locally
```

---

## Reply Representation

A reply is a normal post stored in `posts/`, with two additional metadata fields:

```text
type: reply
target: <post-id-being-replied-to>
```

Level 1 uses the field name `target`, not `reply-to`. The name is already used by this design and can later generalize to other post-like records that point at another post.

### Example

```text
id: 9social:post:550e8400-e29b-41d4-a716-446655440000:4f5b32de-2f02-4f13-bf8c-f0f1a5c7e6a1
author: dennis
date: 1973-10-10T12:15:00Z
type: reply
target: 9social:post:11111111-1111-4111-8111-111111111111:22222222-2222-4222-8222-222222222222
title: Re: Troff and the phototypesetter

That’s exciting work. The ability to produce proper printed output from the same environment could make documentation much easier to manage.
```

---

## Fields

### Required for replies

* `id`
* `author`
* `date`
* `type`
* `target`

### Optional

* `title`

### Field meanings

#### type

For replies:

```text
type: reply
```

This distinguishes replies from ordinary posts.

#### target

The `id` of the post being replied to.

Example:

```text
target: 9social:post:11111111-1111-4111-8111-111111111111:22222222-2222-4222-8222-222222222222
```

---

## Why Target Post IDs?

Replies should point to post IDs, not:

* filenames
* local filesystem paths
* repository names
* URLs

This is because:

* filenames may change
* local paths differ per machine
* repository locations are transport details
* canonical post IDs are the stable global reference

Post IDs use the canonical format defined in the feed format and post creation documents:

```text
9social:post:<user-uuid>:<post-uuid>
```

Both `id` and `target` refer to canonical globally unique post IDs.

---

## Feed Ownership Model

Replies live in the author’s own feed.

This is important.

Example:

* Joe publishes a post with id `9social:post:11111111-1111-4111-8111-111111111111:22222222-2222-4222-8222-222222222222`
* Dennis replies
* Dennis’s reply is stored in Dennis’s feed, not Joe’s

This preserves decentralization and ownership.

---

## Thread Construction

Clients reconstruct threads locally.

A client may determine a thread by:

1. selecting a root post
2. finding all reply posts whose `target` is that post's `id`
3. recursively finding replies to replies

This means thread structure is derived, not stored centrally.

---

## Thread View

A thread view is a client-generated view showing:

* the selected post
* direct replies
* nested replies (optional)

Level 1 does not implement this.

Later clients may provide a command such as:

```sh
9social/thread <post-id>
```

or an ACME tag action like:

```text
Thread
```

---

## Example Thread

Root post:

```text
id: 9social:post:11111111-1111-4111-8111-111111111111:22222222-2222-4222-8222-222222222222
author: joe
date: 1973-10-05T16:20:00Z
title: Troff and the phototypesetter

We got access to a phototypesetter...
```

Reply from Dennis:

```text
id: 9social:post:550e8400-e29b-41d4-a716-446655440000:4f5b32de-2f02-4f13-bf8c-f0f1a5c7e6a1
author: dennis
date: 1973-10-10T12:15:00Z
type: reply
target: 9social:post:11111111-1111-4111-8111-111111111111:22222222-2222-4222-8222-222222222222
title: Re: Troff and the phototypesetter

That’s exciting work...
```

Reply from Lorinda:

```text
id: 9social:post:33333333-3333-4333-8333-333333333333:44444444-4444-4444-8444-444444444444
author: lorinda
date: 1973-10-12T09:05:00Z
type: reply
target: 9social:post:550e8400-e29b-41d4-a716-446655440000:4f5b32de-2f02-4f13-bf8c-f0f1a5c7e6a1

I agree. Better documentation tools will matter a lot.
```

A client can reconstruct:

* Joe post

  * Dennis reply

    * Lorinda reply

---

## Level 1 Implications

Replies are not implemented in Level 1, but Level 1 should preserve the ability to add them cleanly later.

This means Level 1 should already ensure:

### 1. Stable post IDs

All posts need canonical globally unique IDs because replies depend on them.

### 2. Timeline entries should retain post identity

Future timeline/post views should carry enough information to identify the selected post.

### 3. Feed parsing should remain extensible

Post parsing should allow additional metadata fields later without redesigning the format.

---

## Reply Creation UX

The primary Level 1 reply workflow should be Acme-native.

A post opened in Acme may include this tag command:

```text
9social/Reply
```

Level 1 does not require automatic insertion of `9social/Reply` into post window tags. `Reply` should work when invoked from any Acme window whose `$%` names a readable 9social post file. The user may type `9social/Reply` into the tag or body of that window and middle-click it.

Later post-opening or post-view commands may add `9social/Reply` to post window tags automatically.

When the user middle-clicks `9social/Reply`, the command should infer the reply target from the current Acme window. The user should not have to select or type the target post ID.

Expected flow:

1. user opens a post file in Acme
2. user invokes `9social/Reply` from that post window
3. `Reply` reads the current window path from Acme's `$%` environment variable
4. `Reply` parses the post file's `id:` field
5. `Reply` opens a new Acme draft window using the shared `bin/9social/lib/open-draft-window` helper defined by the Acme `NewPost` design
6. on publish, the system creates a new post with:

* `type: reply`
* `target: <post-id-from-original-window>`
* auto-generated `id`
* auto-generated `author`
* auto-generated `date`

The user should not manually enter `target`, `id`, or `author`.

Level 1 `Reply` works only when the current Acme window is a real post file with a valid `id:` field. It should not try to infer a target from a timeline cursor position, selected text, or a synthetic view. Those can be considered later.

`Reply` should validate that the target ID uses the canonical post ID form:

```text
9social:post:<user-uuid>:<post-uuid>
```

The target post file does not need to live in a specific local feed directory. The important value is the canonical post ID in the opened file.

### Opening Reply Targets

When `9social/OpenPost` opens a post that has a syntactically valid `target:` field, it should include `9social/OpenPost` in the Acme window tag.

This supports reply traversal:

1. user opens a reply post
2. user places the cursor on the `target:` value
3. user middle-clicks `9social/OpenPost` in the tag
4. `OpenPost` resolves the target post ID through the local index and opens the target post

This is intentionally Acme-native. The stored reply file remains plain text; the extra command appears only in the window tag.

---

### Target ID Extraction

`Reply` should require Acme's `$%` environment variable to name the current window file.

The path from `$%` must be readable. `Reply` should parse only the post metadata header, stopping at the first blank line, and extract exactly one `id:` field.

The extracted ID must match the canonical post ID form:

```text
9social:post:<user-uuid>:<post-uuid>
```

If `$%` is unset, the file is unreadable, the header has no `id:`, the header has multiple `id:` fields, or the ID is malformed, `Reply` should fail without creating a draft.

A small helper such as `bin/9social/lib/post-id` should do this parsing and validation. Given a post file path, it prints the canonical post ID and exits successfully, or prints an error and exits nonzero. This gives `Reply` a simple tested primitive before adding Acme window behavior.

---

## Draft Experience

A reply draft may look similar to ordinary post creation:

```text
Title: Re: Troff and the phototypesetter

That’s exciting work. The ability to produce proper printed output from the same environment could make documentation much easier to manage.
```

The system fills in the reply metadata automatically on publish.

If the target post has a `title:` field, `Reply` should use it as the initial draft title:

```text
Title: Re: <target title>

```

If the target title already begins with `Re:`, `Reply` should not add another `Re:` prefix.

If the target post has no title, or if title extraction fails, `Reply` should still create a draft with a blank title:

```text
Title:

```

The title is only a starting point. The user may edit it before publishing. A missing or malformed title should not block reply creation as long as the target post has a valid `id:`.

The draft window should not expose system-owned metadata such as `type:` and `target:` for normal user editing. Instead, Level 1 `Reply` should write a sidecar metadata file next to the draft:

```text
<draft>.meta
```

For a reply, the sidecar contains:

```text
type: reply
target: 9social:post:<user-uuid>:<post-uuid>
```

`Publish` and `publish-draft` should read this sidecar, validate it, and include the metadata in the final post file. Ordinary posts created by `NewPost` or `new-post` have no sidecar.

Level 1 sidecar validation is intentionally narrow. `publish-draft` should accept only:

```text
type: reply
target: 9social:post:<user-uuid>:<post-uuid>
```

It should reject unknown fields, duplicate fields, missing `type`, missing `target`, `type` values other than `reply`, and malformed target IDs.

When publishing a reply, `publish-draft` should write sidecar metadata after `date:` and before `title:`:

```text
id: 9social:post:<author-user-uuid>:<new-post-uuid>
author: <author-name>
date: <publication-date>
type: reply
target: 9social:post:<target-user-uuid>:<target-post-uuid>
title: Re: <target title>

<body>
```

If no sidecar exists, `publish-draft` creates an ordinary post and emits no `type:` or `target:` fields.

If publishing succeeds, the draft and sidecar should both be removed. If publishing fails, both should be preserved so the user can retry after fixing the draft. `Cancel` should remove both the draft and sidecar.

---

## Threading and Indexing

At small scale, a client could theoretically scan all posts to find replies.

The Level 1 local index is defined in `14-index.md`.

Replies are indexed under:

```text
$home/lib/9social/index/targets/<encoded-target>/replies/<encoded-reply-id>
```

Each leaf file contains the local path to the reply post file.

This keeps thread lookup fast and avoids repeated full scans during display.

---

## Editing and Deletion

Replies should be treated like ordinary posts:

* they may be edited after publication by their author
* they keep the same `id` when edited
* `date` remains the original publication time

The `target` field should be treated as stable once published.

If a user wants to reply to a different post, they should create a new reply instead of retargeting the old one.

---

## Design Principles

### 1. Replies are posts

No separate reply transport or storage layer.

### 2. Ownership remains local

Each author stores their own replies in their own feed.

### 3. Threads are derived

Clients build thread views from references.

### 4. IDs are canonical

All reply relationships depend on canonical globally unique post IDs.

---

## Limitations (Not in Level 1)

* no reply creation command yet
* no thread view yet
* no nested rendering yet
* no reply indexing yet

---

## Future Extensions

* `in-reply-to` aliases if needed
* richer thread rendering
* quoting selected text in replies
* reply notifications in richer clients
* thread summaries in timeline view

---

## Summary

Replies in 9social are ordinary posts that reference another post by ID.

This keeps the system:

* decentralized
* simple
* filesystem-native
* compatible with Plan 9 design constraints

Thread views are derived locally by clients, not stored centrally.
