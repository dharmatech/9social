
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
* Includes command implementations (e.g. `9social/follow`, `9social/refresh`)
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
    feeds/
    following
```

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
$home/lib/9social/following
```

### Purpose

Stores the list of followed feeds.

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

---

## Command Interaction

### 9social/follow

* Appends URLs to `following`

---

### 9social/refresh

* Reads `following`
* Clones or updates repositories into `feeds/`

---

### 9social/timeline (future)

* Reads posts from all directories under `feeds/`

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
* No metadata or index directories yet
* No caching or partial fetch support

---

## Future Extensions (Not in Level 1)

* `index/` directory for derived data
* `state/` directory for mappings (URL → path → feed ID)
* Improved feed naming strategy
* Archive storage

---

## Summary

The filesystem layout is simple and explicit:

* `following` defines what to fetch
* `feeds/` stores fetched data
* commands operate directly on these paths

This structure enables a minimal, transparent, and composable system.
