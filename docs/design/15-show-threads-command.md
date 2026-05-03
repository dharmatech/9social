# 9social — Acme ShowThreads Command

## Purpose

Display an Acme-native threaded view of locally available posts.

`Timeline` shows a flat chronological list of post summaries.

`ShowThreads` shows reply structure.

The threaded view should prioritize structure over body preview text.

---

## Usage

```rc
9social/ShowThreads
```

`ShowThreads` is intended to be run from Acme.

It opens a new Acme window containing the threaded view.

The window tag should include:

```text
9social/open-post
```

This lets the user place the cursor on a post ID and middle-click `9social/open-post` to open the full post.

---

## Data Source

`ShowThreads` reads local data only.

It depends on the derived local index defined in `14-index.md`:

```text
$home/lib/9social/index/posts
$home/lib/9social/index/targets
```

It may run `9social/reindex` first if the index is missing.

Level 1 should not perform network access.

The user should run `9social/refresh` to update feeds and rebuild the index.

---

## Thread Model

A thread root is any locally available post that does not have `type: reply` with a valid `target:` field.

A reply is any locally available post with:

```text
type: reply
target: 9social:post:<user-uuid>:<post-uuid>
```

Replies are attached to the post whose `id:` matches their `target:`.

If a reply targets a post that is not available locally, that reply is treated as an orphan.

Level 1 may show orphans as separate roots, or omit them with a warning. Recommendation: show orphans as roots with their own reply subtrees so locally available posts are not hidden.

Posts with `type: like` are relationship signals, not discussion nodes.

Level 1 should not show likes in the threaded post list.

---

## Output Format

The threaded view should be compact.

Each entry should show:

* date
* `author:` field value
* canonical post ID
* title

It should not show body preview text in Level 1.

Level 1 should use the post's `author:` field directly. Mapping authors to profile display names can be added later.

Example:

```text
2026-05-02T03:07:00Z  joe
9social:post:5a6118ed-f894-4e9d-8e84-c20ea45f74b9:f6d240b1-c112-4d81-8dde-09cc106706a9
title: A smaller system on the PDP-7

    2026-05-02T03:15:37Z  dharmatech
    9social:post:f9259502-4dde-484c-94b2-1f226226ba70:ae1dc6c1-b26c-4a27-b343-8f8e62796623
    title: Re: A smaller system on the PDP-7
```

Use one tab, or four spaces, per reply depth. Implementation should choose one and keep it consistent.

Recommendation: use four spaces per depth. It displays predictably in Acme and normal terminals.

Separate root threads with a blank line. Do not insert extra blank lines between every reply in a thread.

---

## Sorting

Root threads should be sorted by root post date, newest first.

Replies under a post should be sorted by reply date, oldest first.

Reasoning:

* newest roots keep the overall view useful for recent reading
* oldest-first replies preserve conversational order within a thread

If dates are equal, use a deterministic fallback such as post ID.

There is no artificial maximum reply depth in Level 1.

---

## Acme Behavior

`ShowThreads` should open a new Acme window using the same Acme file interface style as `Timeline` and `NewPost`.

The window body contains the generated threaded view.

The window tag includes:

```text
9social/open-post
```

To open a post:

1. place the cursor on the canonical post ID line
2. middle-click `9social/open-post` in the tag
3. `open-post` resolves the ID through `9social/lib/post-path`

---

## Relationship To Timeline

`timeline` and `Timeline` remain the default chronological view.

`ShowThreads` is a structural view.

It should not replace `Timeline`.

Level 1 may implement only the Acme command `ShowThreads`. A lower-level shell command such as `9social/threads` can be added later if useful.

---

## Missing Or Malformed Data

`ShowThreads` should tolerate malformed local data.

It should skip posts that lack a valid `id:` field.

It should treat posts with malformed `target:` fields as ordinary roots, because they cannot be attached safely.

It should not fail the whole view because one post is malformed.

Warnings may be printed to the Acme errors window.

`ShowThreads` should also defend against cycles in malformed local data. If a cycle is detected during rendering, stop descending that branch, warn, and continue rendering the rest of the view.

---

## Non-Goals

Level 1 `ShowThreads` does not support:

* body previews
* collapsing or expanding threads
* filtering by author
* filtering by date
* pagination
* like counts
* reply counts
* global thread discovery beyond locally available feeds

---

## Implementation Notes

Useful helpers:

* `9social/lib/post-meta`
* `9social/lib/post-path`
* `9social/lib/encode-id`
* `9social/reindex`

The index already maps a post ID to local path and target IDs to reply records.

A straightforward implementation can:

1. scan `index/posts` to collect locally available posts
2. parse each post header with `post-meta`
3. identify roots and replies
4. build parent-child relationships from `target:` values
5. render the thread forest into a temporary file
6. open that file in Acme with `9social/open-post` in the tag
