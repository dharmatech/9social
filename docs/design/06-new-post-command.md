
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

Primary commands:

```rc
9social/new-post      # open an editor
9social/new-post -    # read draft content from stdin
```

With no arguments, this command creates a new post interactively. With `-`, it reads draft content from stdin.

Level 1 accepts only these two forms. Any other argument form is invalid.

Usage on invalid arguments:

```text
usage: 9social/new-post [-]
```

Invalid arguments exit with `usage`. `--help` is not a special success path in Level 1.

### Future Extensions (not required for initial implementation)

```rc
9social/new-post -r <post_id>   # reply
9social/new-post -t <type>      # post type (link, note, etc.)
9social/new-post -e <post_id>   # edit existing post
```

---

## 4. Authoring Flow

Level 1 supports both a terminal-editor workflow and stdin-based draft input.

The lifecycle of a post:

1. User runs:

   ```rc
   9social/new-post
   ```

2. If the command is `9social/new-post -`, system reads stdin into a temporary draft file and skips opening an editor.

3. If the command is `9social/new-post`, system creates a temporary draft file and opens it in an editor:

   * `$editor` if set
   * fallback: `sam`

4. In the editor workflow, user writes post content, saves the draft, and exits the editor.

5. System validates:

   * File is not empty
   * Contains non-whitespace content

6. System generates:

   * Post ID
   * Timestamp
   * Final filename

7. System writes finalized post file into the user’s local publishing feed.

8. System commits the post locally to Git.

9. System does not push the commit.

### Acme

Acme remains the preferred long-term interface, but Level 1 does not require an Acme event loop or tag-based publish command. A user may still run `9social/new-post` from an Acme window or rio shell, but publishing happens when the editor exits.

Future Acme integration may open the draft as editable text and provide a tag command to publish it.

### Stdin Input

`9social/new-post -` receives draft content on stdin:

```rc
echo Hello from 9social | 9social/new-post -
cat draft | 9social/new-post -
```

When `-` is used:

* `9social/new-post -` reads stdin into the temporary draft file
* no editor is opened
* the same draft parsing, validation, metadata generation, file writing, and Git commit rules apply
* this mode exists to support testing, scripts, and ordinary Plan 9 pipelines
* implicit stdin detection is not required in Level 1

### Draft Lifecycle

Level 1 creates the draft in `$home/tmp` if that directory exists. Otherwise it uses `/tmp`.

Draft filenames should be unique for the current command invocation, for example:

```text
9social-new-post.<pid>
```

Rules:

* If publish succeeds, remove the draft file
* If the editor exits and the draft has no meaningful body content, treat the operation as cancelled and remove the draft file
* If the editor command fails, leave the draft file in place and print its path
* If validation fails, leave the draft file in place and print its path
* If writing the final post fails, leave the draft file in place and print its path
* If `git/add` or `git/commit` fails, leave the draft file in place and print its path

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
* `Title:` is recognized only on the first line of the draft
* If the first line starts with `Title:`, that line supplies the draft title
* If the first line is `Title:` but empty or whitespace-only after trimming, treat the title as absent
* If a `Title:` line is present, the next line must be blank, and the body starts after that blank line
* If the first line is not `Title:`, the entire draft is body text
* Body text must contain non-whitespace content after trimming leading and trailing blank lines
* Generated metadata fields such as `id:`, `author:`, and `date:` are not allowed before the body
* Once the body starts, body text is free-form and may contain lines that look like metadata

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
id: 9social:post:f9259502-4dde-484c-94b2-1f226226ba70:8b5f9c8c-98cc-4f5a-8ac4-d3e8b89f0f13
author: dharmatech
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
* `date` is generated at publish time with `date -u -f 'YYYY-MM-DDThh:mm:ss[Z]'`
* `title` is optional; if omitted, timeline views may derive a title from the first body line

---

## 7. Post Identifier Strategy

Each post receives a unique ID.

### Format

```text
9social:post:<user-uuid>:<post-uuid>
```

Example:

```text
9social:post:f9259502-4dde-484c-94b2-1f226226ba70:8b5f9c8c-98cc-4f5a-8ac4-d3e8b89f0f13
```

### Properties

* **Globally unique** by combining the feed owner UUID with a generated post UUID
* **Stable** for the life of the post, including edits
* **Offline-safe** because UUIDs are generated locally
* **Namespaced** so tools can distinguish post IDs from user IDs
* Sorting is handled by `date:` and filenames, not by the post ID

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
* The slug source is the draft title, if present
* If no title is present, the slug source is the first non-empty body line
* Slug text is normalized to lowercase
* Spaces and tabs become hyphens
* Characters outside ASCII `a-z`, `0-9`, and `-` are removed
* Non-ASCII characters are removed in Level 1
* Repeated hyphens are collapsed
* Leading and trailing hyphens are removed
* The slug is capped at 48 characters
* After capping, trailing hyphens are removed again
* If the slug would be empty, use `post`
* If the generated filename already exists in `posts/`, append `-2`, then `-3`, and so on
* The selected filename must still be checked immediately before writing

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

### Profile Requirements

`9social/new-post` reads identity from:

```text
$home/lib/9social/self/profile
```

The profile must contain:

```text
id: 9social:user:<uuid>
name: <short-name>
display: <display-name>
```

Rules:

* `id:` must match `9social:user:<uuid>`
* `<uuid>` must use lowercase dashed UUID format
* `name:` must be present and non-empty
* `display:` must be present and non-empty
* Unknown profile fields are allowed
* `<user-uuid>` for the post ID is extracted from `id:`
* `author:` is generated from `name:`
* `display:` is not used when generating a post

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

### Final Write Safety

Rules:

* `9social/new-post` writes exactly one final post file
* The final post path must not already exist
* If the selected path exists before writing, choose the next filename suffix
* If the selected path exists at write time, abort rather than overwrite
* Do not rename a temporary post file over an existing post
* Editing an existing post is a separate future workflow, not part of `new-post`

---

## 10. Git Integration

Each post is committed to the user’s repository.

### Rules

* **One post = one commit**
* Commits are local only
* `9social/new-post` does not push to the remote repository
* `9social/new-post` writes exactly one new post file
* If the target post file already exists at write time, abort rather than overwrite it
* A clean Git worktree is not required
* Only the new post file is added to Git
* Only the new post file is passed to `git/commit`
* Unrelated modified or untracked files in `$home/lib/9social/self` are left alone
* Unrelated dirty files do not block publishing

### Commit Message

```text
post: <id>
```

Example:

```text
post: 9social:post:f9259502-4dde-484c-94b2-1f226226ba70:8b5f9c8c-98cc-4f5a-8ac4-d3e8b89f0f13
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

### Output

On success, `9social/new-post` prints the final post path relative to `$home/lib/9social/self`:

```text
posted: posts/2026-04-27-my-first-post
```

If `git/commit` also prints a commit line, that output may appear as well. `9social/new-post` should still print the `posted:` line in a stable format.

If the editor exits and the draft has no meaningful body content, treat the operation as cancelled and print:

```text
new-post: cancelled
```

On failure, print the reason to stderr. If a draft file is preserved, also print its path:

```text
draft: /tmp/9social-new-post.<pid>
```

---

## 11. Validation Rules

Before committing:

* `$home/lib/9social/self` must exist
* `$home/lib/9social/self` must be a Git repository
* `$home/lib/9social/self/profile` must exist
* `$home/lib/9social/self/profile` must be a regular file
* `profile` must contain valid `id:`, `name:`, and `display:` fields
* `id:` must match `9social:user:<uuid>`
* `name:` is used as the generated post `author:`
* the user UUID extracted from `id:` is used in the generated post `id:`
* If `$home/lib/9social/self/posts` is missing, create it
* Post must contain non-empty body
* Draft must not contain user-authored generated metadata fields
* Metadata fields must be generated by system (not user-edited)

If validation fails:

* Abort operation
* Notify user

---

## 12. Test Strategy

Level 1 tests should cover stdin mode first, because it exercises the publish path without automating an interactive editor.

Test setup:

* Create a temporary `$home`
* Create `$home/lib/9social/self` as a local Git repository
* Seed `$home/lib/9social/self/profile` with a valid `id: 9social:user:<uuid>`, `name:`, and `display:`

Core stdin test:

* Run `9social/new-post -` with a titled draft on stdin
* Assert the post file exists under `posts/YYYY-MM-DD-slug`
* Assert `id:` has the form `9social:post:<user-uuid>:<post-uuid>`
* Assert `author:` comes from profile `name:`
* Assert `date:` matches `YYYY-MM-DDThh:mm:ssZ`
* Assert `title:` is included when present
* Assert the body is preserved
* Assert Git commits only the new post file
* Assert output includes `posted: posts/...`

Edge tests:

* Untitled draft uses the first non-empty body line as the slug source
* Empty draft cancels
* Bad profile fails
* Filename collision creates `-2`, then `-3`, and so on
* Unrelated dirty files are not committed
* Invalid arguments print `usage: 9social/new-post [-]` and exit with `usage`

Editor-mode testing can be a manual smoke test for Level 1.

---

## 13. Non-Goals (Initial Version)

The following are intentionally **not included**:

* Editing existing posts
* Deleting posts
* Media attachments
* Rich formatting
* Structured content types

These may be introduced in future design documents.

---

## 14. Future Considerations

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

## 15. Summary

The `9social/new-post` command defines the write-path of the system:

* Simple text authoring
* Automatic metadata handling
* Git-backed persistence
* Predictable filesystem layout

This establishes the foundation for all higher-level interactions in 9social.
