# 9social — Local Action Latency

## Purpose

Explore candidate designs for making lightweight local actions feel fast.

The motivating case is `9social/Post/Like`. From Acme, liking a post should feel like a small gesture: the user middle-clicks `9social/Post/Like` and continues reading. If the command performs expensive indexing work synchronously, the interaction feels heavier than the user's intent.

This document records candidate approaches. It is not yet a final implementation plan.

---

## Problem

A like record affects several layers:

* the user's durable feed data under `self/posts/`
* the Git repository for the user's feed
* the local derived index under `$home/lib/9social/index`
* Acme-facing UI decisions, such as whether to show `9social/Post/Like`
* derived views, such as like counts in threaded views

The durable action is small: create one `type: like` record.

The derived work can be much larger: rebuilding the index may scan the user's posts and all followed feed posts.

For fast commands, 9social should distinguish the durable action from derived view maintenance.

---

## Candidate: Commit Now, Index Later

In this model, `9social/like` creates and commits the like record immediately, but does not rebuild the index synchronously.

Flow:

1. Resolve the target post reference.
2. Check that the target is not the user's own post.
3. Check local self posts for an existing like by this user targeting the same post.
4. Create a real `type: like` post under `$home/lib/9social/self/posts/`.
5. Commit the new like post.
6. Return without running `9social/lib/index/rebuild`.

A later `9social/lib/index/rebuild`, `9social/refresh`, or other maintenance command updates the derived index and makes the like visible to count and tag logic.

### Benefits

* Simple mental model: a successful like is immediately a real feed record.
* No local intent queue to manage.
* `9social/push` can publish the like normally.
* The expensive index rebuild is moved out of the interaction path.

### Costs

* The UI may be stale until the next reindex.
* Like counts may not update immediately.
* `OpenPost` may continue to show `9social/Post/Like` for the target until the index catches up.
* Duplicate prevention cannot rely only on the derived index.

### Duplicate Handling

If `like` does not rebuild the index before checking for duplicates, it should check the user's own posts directly.

The authoritative question is:

```text
Does `$home/lib/9social/self/posts` already contain a valid `type: like` record by this user targeting this post ID?
```

Scanning the user's own posts is much cheaper than rebuilding the whole index across self and feeds.

This check can be factored into a helper if this approach is implemented.

---

## Candidate: Local Outbox

In this model, `9social/Post/Like` records a local queued intent instead of creating a feed post immediately.

Example local layout:

```text
$home/lib/9social/outbox/
    likes/
        <timestamp-or-uuid>
```

A queued like file is local working state, not a public feed record.

It may contain only the intent:

```text
type: like
target: 9social:post:<target-user-uuid>:<target-post-uuid>
created: 2026-05-10T12:34:56Z
```

A later ingestion step converts queued intents into real immutable feed records under `self/posts/`, commits them, and updates the index.

### Possible Ingestion Commands

The exact command is intentionally undecided. Candidates include:

* `9social/push` ingests queued actions before pushing
* `9social/sync` ingests, reindexes, and perhaps pushes
* `9social/flush-outbox` only turns queued actions into committed posts

### Benefits

* `Like` can return very quickly.
* Many actions can be batched into one commit and one reindex.
* The model may generalize to other lightweight local actions.
* Queued intents can potentially be inspected, edited, or deleted before publication.

### Costs

* More moving parts than direct feed-post creation.
* A queued like is not yet a public social record.
* `push` must know whether to ingest queued actions.
* Users may need a status view showing pending outbox items.
* Failure modes are more complex: queued, ingested, committed, indexed, and pushed are separate states.

---

## Comparison

### Commit Now, Index Later

This is likely the simpler near-term approach.

It preserves the existing feed model: accepted actions become real posts immediately. Only derived views lag.

### Local Outbox

This is more ambitious.

It may be useful if 9social grows more lightweight actions that should be batched or reviewed before publication. It is probably not necessary just to make `Like` faster.

---

## Current Leaning

For `Like`, first consider **commit now, index later**.

It directly addresses the latency problem while keeping the social data model simple.

Keep the local outbox model as a candidate for future batching and deferred-publication workflows.
