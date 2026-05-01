
# 9social — Overview (Level 1)

## 1. What is 9social?

9social is a **decentralized, filesystem-native social system** designed for Plan 9 / 9front.

Core idea:

> Each user publishes posts as plain text files in their own repository.
> Clients locally fetch these repositories and build a timeline view.

There is:

* no central server
* no global database
* no required service layer

Everything is:

* files
* directories
* simple tools

---

## 2. Core Principles

### 2.1 Plain text first

All data is stored as human-readable text files.

No JSON, no binary formats, no complex schemas.

---

### 2.2 Local-first

A user’s client:

* downloads feeds
* stores them locally
* builds views locally

The system works without continuous network access.

---

### 2.3 Decentralized

Each user controls their own feed repository.

Following someone means:

* knowing their repository URL
* fetching their data

---

### 2.4 Separation of concerns

| Layer        | Responsibility      |
| ------------ | ------------------- |
| Feed repos   | Canonical user data |
| Local store  | Cached feeds        |
| Client tools | Read/merge data     |
| ACME         | User interface      |

---

### 2.5 Identity is inside the data

A feed’s identity is defined by its `profile` file, not:

* directory name
* repository name
* URL

---

## 3. Filesystem Layout

### Source code

```
/usr/glenda/src/9social
```

### Local data

```
$home/lib/9social/
    self/
        following
    feeds/
```

---

### Meaning

* `self/` → the user's own publishing feed repository
* `feeds/` → local clones of followed feeds
* `self/following` → public list of remote feed URLs the user follows

---

## 4. Feed Model

Each user has a feed repository structured like:

```
profile
posts/
```

---

### profile

Contains identity information:

```
id: 9social:user:<uuid>
name: <short-name>
display: <human name>
```

---

### posts/

Contains one file per post.

Each post is:

* an editable document with a stable `id`
* plain text
* self-contained

Future event-like records, such as reactions, may be immutable append-only entries.

---

## 5. Following Model

The user maintains:

```
$home/lib/9social/self/following
```

This file contains **remote repository URLs**, one per line:

```
https://github.com/.../9social-user-dennis.git
https://github.com/.../9social-user-joe.git
```

---

### Following a user

```
9social/follow <url>
```

Adds the URL to `self/following`.

---

### Refreshing feeds

```
9social/refresh
```

For each URL:

* clone if missing
* update if present

---

## 6. Timeline Model

The client builds a timeline by:

1. Reading all posts from followed feeds
2. Merging them
3. Sorting by date/time (newest first)
4. Displaying summaries

---

## 7. User Interface (ACME)

The system is designed for ACME.

### Design rule

> The cursor selects the post; the tag supplies the action.

### Command naming

Lowercase hyphenated command names are used for shell/terminal workflows, for example:

```text
9social/new-post
9social/init-self
```

Capitalized command names are used for Acme tag workflows, for example:

```text
9social/NewPost
9social/Publish
9social/Cancel
```

Level 1 keeps these command families distinct and does not define case aliases.

---

### Timeline window

* shows many posts (summarized)
* user moves cursor to select a post
* actions are triggered via tag commands

---

### Post window

* shows one post in full
* actions apply to that post

---

## 8. Post Creation

User creates posts via:

```
9social/new-post
```

---

### Draft experience

User edits a simple draft:

```
Title: Optional title

Post body text...
```

---

### On publish, the system generates:

* `author`
* `date`
* `id`
* filename

The user does not manage these fields.

---

### Stored format

Posts are saved as:

```
id: ...
author: ...
date: ...
title: ...

Body...
```

In Level 1, `date` should use a UTC ISO 8601 timestamp, for example:

```
date: 1971-05-14T22:43:00Z
```

---

## 9. Command Structure

Commands are namespaced:

```
9social/follow
9social/refresh
9social/timeline
9social/new-post
```

---

## 10. Level 1 Scope

Included:

* local feeds
* following via URLs
* cloning/updating feeds
* timeline generation
* post creation

---

Not included:

* voting
* replies
* threads
* groups
* indexing system
* scalability optimizations

---

## 11. Future Direction (Not Implemented Yet)

Later versions may include:

* reactions (votes)
* replies and threads
* group discussions
* local indexing (derived data)
* archive feeds for scalability

---

## 12. Summary

9social is:

* simple
* file-based
* decentralized
* ACME-native

It builds a social system using:

* text files
* Git repositories
* local computation
