# 9social — Local Index

## Purpose

Define the local derived index used for fast lookup of posts, replies, likes, and other post relationships.

The index is intended to make common local operations fast without changing the canonical feed storage format.

---

## Core Principle

`$home/lib/9social/index` is derived state.

It is not authoritative. It may be deleted and rebuilt from:

```text
$home/lib/9social/self
$home/lib/9social/feeds
```

Commands must treat post files as the source of truth.

If index data disagrees with post files, post files win.

---

## Consequences

Because the index is derived:

* users should not edit it manually
* commands may remove and recreate it during a rebuild
* the index does not need to be committed to the user's self repository
* stale index data is a cache/rebuild problem, not canonical data loss
* deleted posts disappear from the index after a rebuild
* changed post IDs or targets are reflected after a rebuild

---

## Canonical Data

The canonical local data remains:

```text
$home/lib/9social/self/
$home/lib/9social/feeds/
```

`self/` is the user's own Git repository.

`feeds/` contains local clones of followed feed repositories.

The index does not replace either of these directories.

---

## Rebuild Model

A command such as:

```rc
9social/lib/index/rebuild
```

may rebuild the entire index by scanning the local post files under `self/` and `feeds/`.

Level 1 should prefer full rebuilds over incremental updates because full rebuilds are simpler, deterministic, and naturally handle deletions and edits.

Incremental indexing can be added later if full rebuilds become too slow.

---

## Level 1 Layout

Level 1 keeps the existing human-readable post filenames.

The index maps canonical post IDs to local paths, and maps target post IDs to the records that point at them.

```text
$home/lib/9social/index/
    posts/
        <encoded-post-id>
    targets/
        <encoded-target-post-id>/
            replies/
                <encoded-reply-id>
            likes/
                <encoded-like-id>
```

Each leaf file contains exactly one absolute local filesystem path followed by a newline.

Level 1 index leaf files should not copy metadata such as author, date, title, type, or target. Commands that need metadata should read the post file through `9social/lib/post/meta.awk`.

For example:

```text
$home/lib/9social/index/posts/9social_post_f9259502-4dde-484c-94b2-1f226226ba70_ae1dc6c1-b26c-4a27-b343-8f8e62796623
```

may contain:

```text
/usr/glenda/lib/9social/self/posts/2026-05-02-re-a-smaller-system-on-the-pdp-7
```

And:

```text
$home/lib/9social/index/targets/9social_post_9acf94aa-8504-4585-b7e5-2ff0b9847fe3_d74aacda-68ee-4d1c-9f83-35e89a956676/replies/9social_post_f9259502-4dde-484c-94b2-1f226226ba70_ae1dc6c1-b26c-4a27-b343-8f8e62796623
```

may contain the path to the reply post file.

---

## Leaf File Format

Index leaf files are intentionally simple.

Each leaf file contains:

```text
<absolute-local-post-path>
```

with a trailing newline.

There is no additional metadata in Level 1 index leaf files.

Examples:

```text
/usr/glenda/lib/9social/feeds/9social-user-dennis/posts/2026-04-29-multics-and-a-smaller-system
```

or:

```text
/usr/glenda/lib/9social/self/posts/2026-05-02-re-a-smaller-system-on-the-pdp-7
```

This keeps the index easy to inspect and compose with ordinary shell tools such as `cat`, `walk`, `wc`, and `sort`.

If future commands need faster access to summary fields, 9social can add a separate generated summary layer without changing the core ID-to-path index.

---

## Lookup Direction

The index should support both common lookup directions.

Given a local post file, commands can read its `id:` field and derive the index path directly.

Given a post ID, commands can encode the ID and read:

```text
$home/lib/9social/index/posts/<encoded-post-id>
```

This avoids scanning all local feed files when opening a post by ID, counting likes, displaying replies, or resolving relationships from the index back to post files.

Because every valid local post gets an entry in `index/posts/`, post ID to path lookup is fast for ordinary posts, replies, and likes.

---

## ID Encoding

Canonical IDs remain unchanged in post files.

For filenames under `index/`, Level 1 encodes IDs by replacing `:` with `_`.

```text
9social:post:f9259502-4dde-484c-94b2-1f226226ba70:ae1dc6c1-b26c-4a27-b343-8f8e62796623
```

becomes:

```text
9social_post_f9259502-4dde-484c-94b2-1f226226ba70_ae1dc6c1-b26c-4a27-b343-8f8e62796623
```

This keeps canonical IDs readable while avoiding `:` in filenames.

A helper such as:

```rc
9social/lib/encode-id
```

should own this encoding so all commands use the same rule.

---

## Post Path Helper

Add an index-backed helper for resolving a canonical post ID to a local path:

```rc
9social/lib/post-path <post-id>
```

Behavior:

* validate and encode `<post-id>` using the shared ID encoding rule
* read `$home/lib/9social/index/posts/<encoded-post-id>`
* print the absolute local post path
* exit nonzero if the index entry is missing, unreadable, empty, or points to a missing file

Suggested error message:

```text
post not found locally: <post-id>
```

Level 1 `post-path` should not scan `self/` or `feeds/` as a fallback when the index misses.

This keeps ID-to-path lookup predictable and makes stale or missing index state visible. Callers can run `9social/lib/index/rebuild` before retrying if needed.

---

## Open Post Integration

After `post-path` exists, `9social/OpenPost` should accept either a local post path or a canonical post ID.

Supported explicit forms:

```rc
9social/OpenPost /absolute/path/to/post
9social/OpenPost 9social:post:<user-uuid>:<post-uuid>
```

Behavior:

* if the argument starts with `/`, treat it as a local path and open it directly
* if the argument starts with `9social:post:`, resolve it through `9social/lib/post-path`
* if no argument is given, keep the existing Acme current-line behavior
* if the current line contains a full path, open that path
* if the current line contains a post ID, resolve it through `post-path` and open it
* do not scan `self/` or `feeds/` directly as a fallback

When `OpenPost` opens a post in Acme, it should populate the tag with actions appropriate to the post.

Base tags:

* feed post: `| 9social/Post/Reply`
* self post: `| 9social/Post/Reply 9social/Post/Update 9social/Post/Delete`

If the opened post has a syntactically valid `target:` field, `OpenPost` should also add `9social/OpenPost` to the tag. This lets the user place the cursor on the `target:` value and middle-click `9social/OpenPost` to open the target post through the local index.

Examples:

* feed reply: `| 9social/OpenPost 9social/Post/Reply`
* self reply: `| 9social/OpenPost 9social/Post/Reply 9social/Post/Update 9social/Post/Delete`

This lets timeline, thread, and relationship views use either full paths or canonical post IDs while keeping the user-facing `OpenPost` workflow stable.

---

## Post Metadata Helper

Before implementing `reindex`, add a small metadata helper:

```rc
9social/lib/post/meta.awk path
```

`post-meta` reads only the metadata header of a post file and prints normalized tab-separated fields.

For example:

```text
id	9social:post:f9259502-4dde-484c-94b2-1f226226ba70:ae1dc6c1-b26c-4a27-b343-8f8e62796623
author	dharmatech
date	2026-05-02T03:15:37Z
type	reply
target	9social:post:9acf94aa-8504-4585-b7e5-2ff0b9847fe3:d74aacda-68ee-4d1c-9f83-35e89a956676
title	Re: A smaller system on the PDP-7
```

Behavior:

* read from the beginning of the file through the first blank line
* parse existing `key: value` header lines
* ignore the post body
* preserve empty values, such as `title:` as `title	`
* print known fields in file order
* allow unknown fields to pass through or be ignored; `reindex` only needs `id`, `type`, and `target`
* exit nonzero for unreadable files or malformed header lines

`post-meta` should not decide whether a post is indexable. It should parse metadata. Callers such as `reindex`, `timeline`, and future `Like` count logic decide which fields are required for their task.

This keeps `reindex` from growing its own private parser and gives future commands a shared metadata primitive.

---

## Scan Scope

Level 1 `reindex` should scan only the known post directories:

```text
$home/lib/9social/self/posts
$home/lib/9social/feeds/*/posts
```

It should consider only immediate children of those `posts/` directories.

It should not recursively walk nested subdirectories.

Candidate files should exclude:

* directories
* dotfiles such as `.keep`
* non-regular files when the platform makes that distinction available

This matches the current flat post layout and avoids indexing editor backups, future sidecar files, or unrelated content.

If 9social later adopts nested post directories, this rule should be changed deliberately in the feed format and index design together.

---

## Scan Order

`reindex` should use a deterministic scan order.

Order:

1. `$home/lib/9social/self/posts/*`
2. `$home/lib/9social/feeds/*/posts/*`

Feed directories should be processed in sorted order.

Files within each `posts/` directory should be processed in sorted order.

This matters because duplicate post IDs are handled by keeping the first indexed path. Scanning `self/posts` first means the user's own repository wins if the same post ID appears in both `self` and `feeds`.

Deterministic order also makes warnings, tests, and rebuild output repeatable.

---

## Rebuild Algorithm

`9social/lib/index/rebuild` should rebuild the index from scratch:

1. Create a temporary index directory such as `$home/lib/9social/index.tmp.<pid>`.
2. Create `posts` and `targets` inside the temporary index directory.
3. Scan immediate child files under:

```text
$home/lib/9social/self/posts
$home/lib/9social/feeds/*/posts
```

4. For each valid post file, read its canonical `id:` field and write:

```text
index/posts/<encoded-id>
```

containing the post file path.

5. If the post has `type: reply` and a valid `target:`, also write:

```text
index/targets/<encoded-target>/replies/<encoded-reply-id>
```

containing the reply post file path.

6. If the post has `type: like` and a valid `target:`, also write:

```text
index/targets/<encoded-target>/likes/<encoded-like-id>
```

containing the like record file path.

Malformed post files should be skipped with a clear warning, matching the existing timeline behavior.

---

## Rebuild Atomicity

`reindex` should avoid leaving a half-built index behind.

It should build the new index in a temporary sibling directory, such as:

```text
$home/lib/9social/index.tmp.<pid>
```

Then, after the temporary index has been built successfully, it should replace the old index:

1. Create `$home/lib/9social/index.tmp.<pid>`.
2. Build the complete new index in that temporary directory.
3. If the rebuild succeeds structurally:

   * remove the old `$home/lib/9social/index`
   * rename the temporary directory to `$home/lib/9social/index`

4. If the rebuild fails structurally:

   * remove the temporary directory
   * leave the old `$home/lib/9social/index` untouched if it exists
   * exit nonzero

A stale complete index is preferable to a half-built index.

Warnings about malformed individual posts do not count as structural failures and should not prevent the swap.

---

## Refresh Integration

Level 1 should keep `reindex` as a standalone command:

```rc
9social/lib/index/rebuild
```

`9social/cmd/refresh` should run `9social/lib/index/rebuild` automatically after it finishes updating followed feeds.

`refresh` should run `reindex` even if there is no `following` file, or if the following list is empty. This keeps the user's own `self/posts` indexed.

Warnings from `reindex`, such as malformed skipped posts, may be printed directly by `refresh`.

If `reindex` fails structurally, `refresh` should exit nonzero after reporting that feed refresh completed but index rebuild failed.

Level 1 should rebuild the full index every time `refresh` runs. This is simpler than detecting whether feeds changed, and it also catches local edits or deletes in `self/posts`.

This makes the index naturally track local feed updates without making indexing part of the Git transport model.

---

## Malformed Data Policy

`9social/lib/index/rebuild` should be tolerant of malformed post files.

A malformed post file should not prevent the rest of the index from being rebuilt.

When `reindex` finds malformed data, it should:

* print a warning that includes the path
* skip the malformed post or relationship
* continue indexing the remaining valid posts

This matches the existing `timeline` behavior, where bad post files are skipped rather than stopping the whole timeline.

For `index/posts`, a post file must have a valid canonical `id:` field. If the `id:` field is missing or malformed, the post cannot be indexed by ID and should be skipped.

For relationship entries under `index/targets`, a post must have:

* a valid canonical `id:` field
* `type: reply` or `type: like`
* a valid canonical `target:` field

If the post has a valid `id:` but an invalid relationship field, `reindex` may still add the post to `index/posts` while skipping the relationship entry.

`reindex` should exit nonzero only when the rebuild itself cannot complete, such as when it cannot create `$home/lib/9social/index` or cannot write required index files.

Warnings about individual malformed posts are not fatal.

---

## Counts

The first index implementation should not include count or display helpers.

Implement the core primitives first:

* `9social/lib/encode-id`
* `9social/lib/post/meta.awk`
* `9social/lib/index/rebuild`
* `9social/lib/post-path`
* refresh integration
* `OpenPost` ID support

After those are working, future helpers may include:

```rc
9social/lib/reply-count <post-id>
9social/lib/like-count <post-id>
```

`reply-count` may count raw reply entries under:

```text
index/targets/<encoded-target>/replies
```

`like-count` should not blindly count raw files, because historical duplicate likes from the same author may exist. It should read like records and count at most one like per `(author, target)` pair.

Keeping counts out of the first index pass makes the implementation and tests smaller.

---

## Missing Targets

Relationship records may point to target posts that are not present locally.

For example, a followed user may reply to or like a post by someone the local user does not follow.

`reindex` should still index those relationship records under:

```text
index/targets/<encoded-target>/replies/<encoded-reply-id>
index/targets/<encoded-target>/likes/<encoded-like-id>
```

It should not require the target post to exist in:

```text
index/posts/<encoded-target>
```

Relationships are facts about canonical post IDs. A reply or like can be valid even when the target post is not available in the local feed cache.

Commands that try to open or display the target post may later report that the target is not found locally.

---

## Duplicate Data Policy

Duplicate canonical post IDs are malformed data.

If two post files claim the same `id:`, `reindex` should:

* print a warning that includes both the duplicate path and the already-indexed path when possible
* keep the first path it indexed in `index/posts`
* skip the later duplicate for `index/posts`
* skip relationship indexing for the later duplicate, because its identity is ambiguous
* continue rebuilding the rest of the index

Duplicate relationship targets are normal. Many replies may target the same post, and many likes from different authors may target the same post.

Historical duplicate likes from the same author to the same target may exist. `reindex` should tolerate them and index the raw records. Higher-level commands that display counts should deduplicate likes by `(author, target)`.

Once the index exists, `9social/Post/Like` should avoid creating new duplicate likes by checking the indexed likes for the target before writing a new like record.

---

## Implementation Order

Implement the index branch from smallest primitives to larger command integration.

Recommended order:

1. `9social/lib/encode-id`
2. `9social/lib/post/meta.awk`
3. `9social/lib/index/rebuild`
4. `9social/lib/post-path`
5. update `9social/OpenPost` to accept canonical post IDs
6. update `9social/cmd/refresh` to run `9social/lib/index/rebuild`
7. later: update `9social/Post/Like` to use the index for idempotency

`Like` idempotency should wait until the core index primitives are working and tested.

This order keeps each step small and gives every larger command a tested helper to build on.

---

## Test Plan

Index work should be implemented with focused tests for each small helper and command.

Minimum tests:

### `9social/lib/encode-id`

* encodes `9social:post:<user-uuid>:<post-uuid>` as `9social_post_<user-uuid>_<post-uuid>`
* rejects malformed post IDs

### `9social/lib/post/meta.awk`

* parses ordinary post headers
* preserves empty values such as `title:`
* stops at the first blank line
* ignores post body text
* fails on malformed header lines
* fails on unreadable or missing files

### `9social/lib/index/rebuild`

* creates `index/posts/<encoded-id>` for self posts
* creates `index/posts/<encoded-id>` for feed posts
* creates `index/targets/<encoded-target>/replies/<encoded-reply-id>` for replies
* creates `index/targets/<encoded-target>/likes/<encoded-like-id>` for likes
* indexes relationships even when the target post is missing locally
* skips dotfiles such as `.keep`
* warns and continues for malformed post files
* handles duplicate post IDs by keeping the first indexed path
* uses deterministic scan order, with `self/posts` before `feeds/*/posts`
* preserves the old complete index if a structural rebuild failure can be tested cleanly

### `9social/lib/post-path`

* resolves a valid indexed post ID to an absolute local path
* fails when the index entry is missing
* fails when the indexed path no longer exists
* does not scan `self/` or `feeds/` as a fallback

### `9social/OpenPost`

* still opens explicit absolute paths
* resolves explicit canonical post IDs through `post-path`
* keeps existing Acme current-line path behavior
* can resolve a current-line post ID through `post-path`

### `9social/cmd/refresh`

* runs `reindex` after feed processing
* still rebuilds the index when no `following` file exists
* still rebuilds the index when `following` exists but is empty
* exits nonzero if `reindex` fails structurally

These tests should run under the existing 9social test harness and should avoid network access.

