
# 9social — Filesystem Layout (Level 1)

## Purpose

Define the canonical filesystem structure used by 9social.

All commands and tools rely on these paths.

---

## Root Directories

### Source Code

```text
/usr/glenda/src/9social
```

* Contains all 9social source code
* Includes command implementations (e.g. `9social/cmd/follow`, `9social/cmd/refresh`)
* Includes design documents

---

### Local Data Store

```text
$home/lib/9social
```

* Contains all runtime data
* Managed by 9social commands

---

## Data Directory Structure

```text
$home/lib/9social/
    self/
        profile
        following
        posts/
    feeds/
    index/
```

---

## self/

```text
$home/lib/9social/self/
```

### Purpose

Stores the user's own publishing feed repository.

This repository is where `9social/cmd/new-post` writes new posts and where `9social/cmd/follow` records the public follow list.

---

### Structure

```text
self/
    profile
    following
    posts/
```

---

### Notes

* `self/` is a Git repository controlled by the user
* It has the same feed structure as followed feeds
* Level 1 does not support placing the publishing feed at another path
* Initial setup is handled separately from post creation

---

## feeds/

```text
$home/lib/9social/feeds/
```

### Purpose

Stores local copies of followed feeds.

Each subdirectory represents one feed repository.

---

### Structure

```text
feeds/
    <feed-name>/
```

Example:

```text
feeds/
    9social-user-dennis/
    9social-user-joe/
```

---

### Notes

* Each directory is a cloned repository
* Directory names are derived from repository names (Level 1)
* Directory names are **not authoritative identifiers**
* Future versions may change naming strategy

---

## following

```text
$home/lib/9social/self/following
```

### Purpose

Stores the public list of followed feeds.

`following` is part of `self/` so other users can see who this user follows after the self repository is pushed.

---

### Format

* Plain text file
* One URL per line
* No additional structure (Level 1)

Example:

```text
https://github.com/dharmatech/9social-user-dennis.git
https://github.com/dharmatech/9social-user-joe.git
```

---

### Notes

* This file is the source of truth for followed feeds
* It is safe to edit manually
* Duplicate entries should be avoided
* If `self/` is not initialized yet, `follow` may create a minimal `self/` containing only `following`

---

## Command Interaction

### 9social/cmd/follow

* Adds URLs to `self/following`, deduplicates, and sorts it

---

### 9social/cmd/refresh

* Reads `self/following`; missing `following` means no feeds are configured
* Clones or updates repositories into `feeds/`

---

### 9social/cmd/new-post

* Writes new posts into `self/posts/`
* Commits new posts locally in `self/`
* Does not push commits

---

### 9social/cmd/timeline

* Reads posts from `self/posts/` and all directories under `feeds/`

---

## Design Principles

### 1. Clear separation of concerns

| Path                      | Purpose      |
| ------------------------- | ------------ |
| `/usr/glenda/src/9social` | Source code  |
| `$home/lib/9social`       | Runtime data |

---

### 2. Filesystem is the API

All state is represented as files and directories.

There is:

* no hidden database
* no opaque storage layer

---

### 3. Local-first design

All feed data is stored locally.

Commands operate on local data after `refresh`.

---

## Limitations (Level 1)

* No collision handling for feed directory names
* No network caching or partial fetch support
* `index/` is derived cache data and may be rebuilt

---

## Future Extensions (Not in Level 1)

* More detailed state mappings, such as URL → path → feed ID
* Improved feed naming strategy
* Archive storage

---

## Summary

The filesystem layout is simple and explicit:

* `self/` stores the user's own feed
* `self/following` defines what to fetch and is part of the public self repository
* `feeds/` stores fetched data
* `index/` stores derived cache data
* commands operate directly on these paths

This structure enables a minimal, transparent, and composable system.
