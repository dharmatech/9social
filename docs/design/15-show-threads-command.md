# 9social — Thread View Commands

## Purpose

Display a threaded view of locally available posts from the command line and from Acme.

`Timeline` shows a flat chronological list of post summaries.

`ShowThreads` shows reply structure.

The threaded view should prioritize structure over body preview text.

---

## Commands

### Command-line core

```rc
9social/cmd/show-threads
```

`show-threads` is the non-interactive core command. It writes the threaded view to standard output.

It does not require Acme. This command is suitable for terminal workflows, automated tests, and scripts that want the threaded view as plain text.

Invalid arguments print:

```text
usage: 9social/cmd/show-threads
```

and exit with `usage`.

If local indexing cannot be prepared, `show-threads` should print a command-prefixed error and exit nonzero.

### Acme wrapper

```rc
9social/ShowThreads
```

`ShowThreads` is an Acme command and thin wrapper around `show-threads`.

It creates a temporary file, runs:

```rc
9social/cmd/show-threads > <temp-file>
```

and opens that file in a new Acme window.

The window tag should include:

```text
9social/OpenPost
```

This lets the user place the cursor on a post ID and middle-click `9social/OpenPost` to open the full post.

---

## Data Source

`show-threads` reads local data only.

It depends on the derived local index defined in `14-index.md`:

```text
$home/lib/9social/index/posts
$home/lib/9social/index/targets
```

`show-threads` may run `9social/lib/index/rebuild` first if the index is missing.

If `index/rebuild` fails, or if `$home/lib/9social/index/posts` still does not exist after rebuilding, `show-threads` should fail clearly rather than rendering a partial view.

Level 1 should not perform network access.

The user should run `9social/cmd/refresh` to update feeds and update the index.

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
* optional like count
* optional direct reply count
* canonical post ID
* title

It should not show body preview text in Level 1.

Level 1 should use the post's `author:` field directly. Mapping authors to profile display names can be added later.

Counts are shown on the first line after the author, using compact labels:

```text
L:<like-count> R:<reply-count>
```

Omit each count independently when it is zero. For example, show `L:4`, `R:2`, `L:4 R:2`, or no count suffix.

`R:n` means direct replies only, not total descendants.

`L:n` counts current unique likes by author for the post. Until `Unlike` exists, this means at most one valid `type: like` record per `(author, target)` pair.

Counts are local and viewer-relative. They are derived only from local `self` and refreshed `feeds` data.

Counts are generated view data, not stored in the canonical post file.

Malformed like records should be ignored for counts. They may produce warnings, but they should not prevent `ShowThreads` from rendering.

Duplicate like records from the same `author:` for the same target count once.

No special counting rule is needed for self-likes. The `Like` command prevents creating them, but if a valid manually-created like exists locally, count logic can treat it like any other valid like record.

Example:

```text
2026-05-02T03:07:00Z  joe L:4 R:2
9social:post:5a6118ed-f894-4e9d-8e84-c20ea45f74b9:f6d240b1-c112-4d81-8dde-09cc106706a9
title: A smaller system on the PDP-7

    2026-05-02T03:15:37Z  dharmatech
    9social:post:f9259502-4dde-484c-94b2-1f226226ba70:ae1dc6c1-b26c-4a27-b343-8f8e62796623
    title: Re: A smaller system on the PDP-7
```

Use one tab, or four spaces, per reply depth. Implementation should choose one and keep it consistent.

Recommendation: use four spaces per depth. It displays predictably in Acme and normal terminals.

Separate root threads with a blank line.

Also separate sibling replies with a blank line when they share the same parent. Do not insert a blank line between a parent and its first reply, because that weakens the visual parent-child relationship.

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

`ShowThreads` should contain only the Acme-specific behavior.

It should create a temporary file, run `9social/cmd/show-threads` into that file, and open a new Acme window using the same Acme file interface style as `Timeline` and `NewPost`.

The window body contains the generated threaded view.

The window tag includes:

```text
9social/OpenPost
```

To open a post:

1. place the cursor on the canonical post ID line
2. middle-click `9social/OpenPost` in the tag
3. `OpenPost` resolves the ID through `9social/lib/post/path`

---

## Relationship To Timeline

`timeline` and `Timeline` remain the default chronological view.

`show-threads` and `ShowThreads` are structural views.

They should not replace `timeline` or `Timeline`.

The lowercase `show-threads` command provides the terminal and testable core. The uppercase `ShowThreads` command provides the Acme presentation.

---

## Missing Or Malformed Data

`show-threads` should tolerate malformed local data.

It should skip posts that lack a valid `id:` field.

It should treat posts with malformed `target:` fields as ordinary roots, because they cannot be attached safely.

It should not fail the whole view because one post is malformed.

Warnings may be printed to the Acme errors window.

`show-threads` should also defend against cycles in malformed local data. If a cycle is detected during rendering, stop descending that branch, warn, and continue rendering the rest of the view.

---

## Non-Goals

Level 1 thread views do not support:

* body previews
* collapsing or expanding threads
* filtering by author
* filtering by date
* pagination
* global thread discovery beyond locally available feeds

---

## Implementation Notes

Useful helpers:

* `9social/lib/post/meta.awk`
* `9social/lib/post/path`
* `9social/lib/id/encode.awk`
* `9social/lib/index/rebuild`

The index already maps a post ID to local path and target IDs to reply records.

A straightforward `show-threads` implementation can:

1. ensure `index/posts` exists, running `9social/lib/index/rebuild` if needed
2. scan `index/posts` to collect locally available posts
3. parse each post header with `9social/lib/post/meta.awk`
4. identify roots and replies
5. build parent-child relationships from `target:` values
6. calculate `R:n` from the in-memory direct-child reply lists
7. calculate `L:n` from `index/targets/<encoded-id>/likes`, counting unique valid like authors
8. render the thread forest to standard output

A straightforward `ShowThreads` implementation can:

1. create a temporary file
2. run `9social/cmd/show-threads > <temp-file>`
3. open that file in Acme with `9social/OpenPost` in the tag

For Level 1, count calculation can live inside `9social/lib/render/thread-records.awk`. A separate count helper can be extracted later if other views need the same data.

When a future `Unlike` record exists, update like counting to use the latest valid like/unlike event for each `(author, target)` pair.
