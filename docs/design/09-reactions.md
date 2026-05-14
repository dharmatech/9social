
# 9social — Reactions (Votes)

## Purpose

Define how reactions are represented in 9social.

The general reaction model is broader than the current implementation. Level 1 currently implements `type: like` as the first concrete reaction command; other reactions remain future work. This design influences:

- post identity
- indexing strategy
- feed ingestion
- timeline enrichment

---

## Core Principle

> A reaction is represented as an immutable event-like record that references another post.

Reactions are not stored centrally and do not modify the original post.

They are published in the reacting user’s own feed.

---

## Basic Model

If Dennis upvotes a post by Joe:

- Dennis publishes a reaction post in his own feed
- that reaction references Joe’s post by ID
- clients derive vote counts locally

---

## Reaction Representation

A concrete like is a post with:

- `type`
- `target`

A future generic reaction record may also add a `reaction` field.

### Generic Reaction Example

```text
id: 9social:post:dennis-1973-10-10T12:30:00Z-upvote-joe-troff
author: dennis
date: 1973-10-10T12:30:00Z
type: reaction
target: 9social:post:joe-1973-10-05T16:20:00Z-troff
reaction: upvote

```

---

## Fields

### Required for current likes

* `id`
* `author`
* `date`
* `type`
* `target`

### Possible for future generic reactions

* `reaction`

---

### Field meanings

#### type

```text
type: like
```

Identifies this post as a like event. A future generic reaction record may use another `type:` value.

---

#### target

The ID of the post being reacted to.

```text
target: 9social:post:joe-1973-10-05T16:20:00Z-troff
```

---

#### reaction

A separate `reaction:` field is not used by the current `type: like` implementation. It remains a possible future extension if 9social adds a generic reaction event type.

---

## Reaction Types

Currently implemented:

* `like`

Future possibilities:

* `bookmark`
* `flag`
* other explicit reaction types

---

## Ownership Model

Reactions are stored in the reacting user’s feed.

Example:

* Joe publishes post
* Dennis upvotes
* Dennis’s feed contains the reaction

This preserves:

* decentralization
* user ownership
* append-only event history

---

## Aggregation Model

Clients derive reaction counts locally.

Example:

If a client follows:

* Joe
* Dennis
* Alan

and Dennis and Alan both upvote Joe’s post:

Then the client displays:

```text
2 upvotes (Dennis, Alan)
```

---

## Scope of Visibility

Reaction counts are **relative to the viewer**.

Only reactions from followed feeds are considered.

This results in:

* small, personal views of popularity
* no global authoritative count
* no need for central coordination

---

## Removing a Reaction

Reactions are append-only events.

A user does not delete a previous reaction.

Instead, they publish a new reaction event, and clients determine the current state from the event stream.

The canonical Level 1-style removal form is:

```text
reaction: remove-upvote
```

---

## Reaction Resolution

For each `(author, target)` pair:

* the latest reaction event determines the current state

This is the canonical local resolution rule for reactions.

---

## Timeline Behavior

Reactions should not appear as ordinary posts in the default timeline view.

Clients may later offer:

* reaction-aware post views
* optional activity views
* optional filters that expose reaction events directly

---

## UI Behavior (Future)

In ACME or other clients:

* selecting a post allows:

  * `Upvote`
  * `RemoveUpvote`

These actions create new reaction posts.

---

## Indexing

Without indexing, reactions would require scanning all posts.

The concrete Level 1 local index is defined in `14-index.md`.

Like reactions are indexed under:

```text
$home/lib/9social/index/targets/<encoded-target>/likes/<encoded-like-id>
```

Each leaf file contains the local path to the like record file.

Other reaction types should follow the same target-oriented shape if they are added later.

---

## Level 1 Implications

For reactions, Level 1 should:

### 1. Preserve post IDs

Reactions depend on canonical globally unique post IDs.

---

### 2. Allow extensible metadata

Post parsing should allow additional fields like:

```text
type:
target:
reaction:
```

The current concrete like pattern is:

```text
type: like
target: <canonical-post-id>
```

A broader future reaction vocabulary may add another reaction-specific field if needed.

---

### 3. Maintain append-only model

Clients should treat reactions as immutable append-only event records.

---

## Design Principles

### 1. Reactions are events

They are immutable records of user intent.

---

### 2. No central state

There is no global vote count.

All aggregation is local.

---

### 3. Local perspective

Each user sees reactions based on who they follow.

---

### 4. Composable system

Reactions reuse the same feed transport and parsing model as posts and replies, while remaining a distinct immutable event-like record category.

---

## Limitations (Not in Level 1)

* no generic reaction command yet
* no unlike command yet
* no filtering yet

---

## Future Extensions

* multiple reaction types
* weighted reactions
* trust-based filtering
* reaction summaries in timeline
* reaction notifications

---

## Summary

Reactions in 9social are:

* posts
* referencing another post
* stored in the user’s own feed
* aggregated locally by clients

This keeps the system:

* decentralized
* simple
* extensible
* consistent with Plan 9 design philosophy

```

---

## 🧠 Why this is important now

Even though you won’t implement it yet, this doc:

- locks in the **event-based model**
- ensures `timeline` doesn’t assume posts are isolated
- informs future indexing decisions
- keeps everything consistent with replies
