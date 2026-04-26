
# **Design Document 06: Post Creation**

## 1. Overview

This document defines how a user creates a new post in 9social.

Post creation is a core primitive of the system. It establishes:

* The authoring workflow
* The post file format
* The identifier scheme
* The Git commit model

This design prioritizes simplicity, human readability, and alignment with Plan 9 principles.

---

## 2. Goals

* **Text-first authoring**
  Users create posts by editing plain text.

* **No manual metadata management**
  The system generates IDs, timestamps, and filenames.

* **Works in multiple environments**
  Compatible with:

  * Acme
  * rio terminal workflows
  * Remote sessions (drawterm)

* **Local-first operation**
  No network access required to create posts.

---

## 3. Command Interface

Primary command:

```rc
9social/new-post
```

This command creates a new post interactively.

### Future Extensions (not required for initial implementation)

```rc
9social/new-post -r <post_id>   # reply
9social/new-post -t <type>      # post type (link, note, etc.)
9social/new-post -e <post_id>   # edit existing post
```

---

## 4. Authoring Flow

The lifecycle of a post:

1. User runs:

   ```rc
   9social/new-post
   ```

2. System creates a temporary draft file.

3. In Acme, the system opens the draft as editable text and provides a tag command to publish it.

   In non-Acme workflows, the system may open the draft in an editor:

   * `$editor` if set
   * fallback: `sam`

4. User writes post content.

5. User publishes the draft from Acme, or saves and exits the editor in a terminal workflow.

6. System validates:

   * File is not empty
   * Contains non-whitespace content

7. System generates:

   * Post ID
   * Timestamp
   * Final filename

8. System writes finalized post file into the user’s local publishing feed.

9. System commits the post locally to Git.

10. System does not push the commit.

---

## 5. Draft Format

The draft is plain text.

### Format

```text
Title: Optional title

Post body text...
```

### Rules

* `Title:` is optional
* If `Title:` is absent, no `title:` header is written to the final post
* If `Title:` is present but empty or whitespace-only, treat it as absent
* Body text starts after the first blank line
* Body text must contain non-whitespace content after trimming leading and trailing blank lines
* User-authored metadata fields such as `id:`, `author:`, and `date:` are not allowed in the draft

---

## 6. Post File Format

Posts are stored as plain text files with a simple header.

### Format

```text
id: <id>
author: <profile-name>
date: <timestamp>
title: <title>   (optional)

<body>
```

### Example

```text
id: 20260425T142700Z-glenda
author: glenda
date: 2026-04-25T14:27:00Z
title: My first post

This is my first post on 9social.
```

---

### Design Notes

* Header is line-based and human-readable
* Blank line separates metadata from body
* Body is free-form text
* No strict parsing requirements beyond simple key/value
* `author` is generated from the `name:` field in `$home/lib/9social/self/profile`
* `title` is optional; if omitted, timeline views may derive a title from the first body line

---

## 7. Post Identifier Strategy

Each post receives a unique ID.

### Format

```text
<timestamp>-<username>
```

Example:

```text
20260425T142700Z-glenda
```

### Properties

* **Sortable** (lexicographically ordered by time)
* **Globally unique (practically)**
* **Human-readable**
* **Offline-safe**

---

## 8. Filename Generation

Each post receives a generated filename.

The filename is only a local storage name within the feed's `posts/` directory.
It is not the canonical identity of the post.

### Format

```text
YYYY-MM-DD-slug
```

Example:

```text
2026-04-25-my-first-post
```

### Rules

* `YYYY-MM-DD` comes from the generated UTC `date:` timestamp
* The slug comes from the draft title, if present
* If no title is present, the slug comes from the first non-empty body line
* Slug text is normalized to lowercase
* Spaces become hyphens
* Characters outside `a-z`, `0-9`, and `-` are removed
* Repeated hyphens are collapsed
* Leading and trailing hyphens are removed
* The slug is capped at 48 characters
* If the slug would be empty, use `post`
* If the generated filename already exists in `posts/`, append `-2`, then `-3`, and so on

### Notes

* Filenames only need to be unique within the user's own `posts/` directory
* Different feeds may use the same filename
* The post `id:` field is the canonical globally unique post identifier

---

## 9. Filesystem Layout

Posts are stored in the user’s local publishing feed.

### Base Path

```text
$home/lib/9social/self/
```

This path is the canonical Level 1 location for the user's own feed repository.
The repository has the same structure as any other 9social feed:

```text
$home/lib/9social/self/
    profile
    posts/
```

Level 1 does not support placing the publishing feed at another path.

### Posts Directory

```text
$home/lib/9social/self/posts/
```

### Example

```text
$home/lib/9social/self/posts/2026-04-25-first-post
```

### Design Notes

* Level 1 uses a flat `posts/` directory
* `9social/new-post` creates `posts/` if it does not already exist
* Filenames should be human-readable and sortable
* The post `id:` field, not the filename, is the canonical identifier

---

## 10. Git Integration

Each post is committed to the user’s repository.

### Rules

* **One post = one commit**
* Commits are local only
* `9social/new-post` does not push to the remote repository
* `9social/new-post` writes exactly one new post file
* If the target post file already exists at write time, abort rather than overwrite it
* Only the new post file is added to Git
* Unrelated modified or untracked files in `$home/lib/9social/self` are left alone

### Commit Message

```text
post: <id>
```

Example:

```text
post: 20260425T142700Z-glenda
```

### Rationale

* Enables synchronization via Git
* Preserves a local publication history
* Supports distributed replication
* Allows the user to create multiple posts while offline and push later

Remote repository creation is outside the scope of `9social/new-post`.
The initial setup of `$home/lib/9social/self` should be handled by a separate command, such as:

```rc
9social/init-self <git-url>
```

That setup command is responsible for cloning the user's remote repository into `$home/lib/9social/self`.

### Failure Handling

If writing the post file fails, abort without committing.

If `git/add` or `git/commit` fails:

* leave the new post file in place
* report the failure
* do not delete the post file automatically

---

## 11. Validation Rules

Before committing:

* `$home/lib/9social/self` must exist
* `$home/lib/9social/self` must be a Git repository
* `$home/lib/9social/self/profile` must exist
* `$home/lib/9social/self/profile` must contain a `name:` field
* If `$home/lib/9social/self/posts` is missing, create it
* Post must contain non-empty body
* Draft must not contain user-authored generated metadata fields
* Metadata fields must be generated by system (not user-edited)

If validation fails:

* Abort operation
* Notify user

---

## 12. Non-Goals (Initial Version)

The following are intentionally **not included**:

* Editing existing posts
* Deleting posts
* Media attachments
* Rich formatting
* Structured content types

These may be introduced in future design documents.

---

## 13. Future Considerations

This design enables future features:

* Replies (`reply_to` field)
* Threading
* `type:` field for replies, reactions, links, or other post-like records
* Reactions/upvotes
* Search and indexing
* A setup command such as `9social/init-self <git-url>`
* A push command for publishing local commits
* A sync command that may combine refreshing followed feeds with pushing the user's self feed
* Nested or archive post storage if flat directories become too large

---

## 14. Summary

The `9social/new-post` command defines the write-path of the system:

* Simple text authoring
* Automatic metadata handling
* Git-backed persistence
* Predictable filesystem layout

This establishes the foundation for all higher-level interactions in 9social.
