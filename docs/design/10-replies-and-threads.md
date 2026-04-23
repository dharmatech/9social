
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

A reply is a post with an added `type` field and a `target` field.

### Example

```text
id: 9social:post:dennis-1973-10-10T12:15:00Z-reply-joe-troff
author: dennis
date: 1973-10-10T12:15:00Z
type: reply
target: 9social:post:joe-1973-10-05T16:20:00Z-troff
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
target: 9social:post:joe-1973-10-05T16:20:00Z-troff
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

In later design work, the exact post ID generation scheme should be specified more precisely.
For now, this document assumes that `id` and `target` refer to canonical globally unique post IDs.

---

## Feed Ownership Model

Replies live in the author’s own feed.

This is important.

Example:

* Joe publishes post `joe-1973-10-05-troff`
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
id: 9social:post:joe-1973-10-05T16:20:00Z-troff
author: joe
date: 1973-10-05T16:20:00Z
title: Troff and the phototypesetter

We got access to a phototypesetter...
```

Reply from Dennis:

```text
id: 9social:post:dennis-1973-10-10T12:15:00Z-reply-joe-troff
author: dennis
date: 1973-10-10T12:15:00Z
type: reply
target: 9social:post:joe-1973-10-05T16:20:00Z-troff
title: Re: Troff and the phototypesetter

That’s exciting work...
```

Reply from Lorinda:

```text
id: 9social:post:lorinda-1973-10-12T09:05:00Z-reply-dennis-troff
author: lorinda
date: 1973-10-12T09:05:00Z
type: reply
target: 9social:post:dennis-1973-10-10T12:15:00Z-reply-joe-troff

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

A future client may support reply creation like this:

1. user opens a post
2. user invokes `Reply`
3. client opens a draft
4. on publish, client creates a new post with:

* `type: reply`
* `target: <selected-post-id>`
* auto-generated `id`
* auto-generated `author`
* auto-generated `date`

The user should not manually enter `target`, `id`, or `author`.

---

## Draft Experience

A reply draft may look similar to ordinary post creation:

```text
Title: Re: Troff and the phototypesetter

That’s exciting work. The ability to produce proper printed output from the same environment could make documentation much easier to manage.
```

The system fills in the reply metadata automatically on publish.

---

## Threading and Indexing

At small scale, a client could theoretically scan all posts to find replies.

At larger scale, replies should be indexed locally.

A future indexing system may maintain derived files such as:

```text
$home/lib/9social/index/replies/<post-id>
```

containing the IDs of replies targeting that post.

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
