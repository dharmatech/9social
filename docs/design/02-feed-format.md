
# 9social — Feed Format (Level 1)

## Purpose

Define the structure and format of a 9social feed.

A feed is a directory (typically a Git repository) that contains:
- identity information
- a collection of posts

---

## Feed Structure

Each feed has the following layout:

```text
profile
posts/
```

---

## profile

### Purpose

Defines the identity of the feed owner.

---

### Format

Plain text file with key-value pairs:

```text
id: <unique-id>
name: <short-name>
display: <display-name>
```

Parsing rules:

* One field per line
* Each field uses the form `key: value`
* A line without a colon is invalid in Level 1

---

### Fields

#### id

* Globally unique identifier for the feed
* Must be stable over time
* Example:

```text
id: dennis-ritchie-demo
```

---

#### name

* Short identifier (not required to be globally unique)
* Used in references and compact displays
* Example:

```text
name: dennis
```

---

#### display

* Human-readable name
* Used in UI output
* Example:

```text
display: Dennis Ritchie
```

---

### Notes

* The `profile` file is required
* Additional fields may be added in future versions
* Identity is defined by this file, not by directory or repository name

---

## posts/

### Purpose

Contains all posts published by the feed owner.

---

### Structure

```text
posts/
    <post-file>
    <post-file>
    ...
```

* One file per post
* Filenames are human-readable and sortable
* Filenames are **not authoritative identifiers**

---

## Post Format

Each post file is a plain text file with two sections:

1. Metadata header
2. Body

---

### Metadata Header

Key-value pairs at the top of the file:

```text
id: <post-id>
author: <author-name>
date: <date>
title: <title>   (optional)
```

Header parsing rules:

* One field per line
* Each field uses the form `key: value`
* The first blank line ends the header
* Everything after that blank line is the body
* Unknown header fields may be ignored in Level 1

---

### Body

A blank line separates the header from the body:

```text
<blank line>
<post content>
```

---

### Full Example

```text
id: dennis-1967-06-15-bell-labs
author: dennis
date: 1967-06-15
title: Just settled into Bell Labs

It’s an extraordinary place—lots of very sharp people working on everything from communications theory to operating systems. I’ve been getting oriented and meeting folks in the computing research group. There’s a lot of discussion around time-sharing systems and how to make them more usable.
```

---

## Field Definitions

### id

* Unique identifier for the post
* Must be stable
* Generated automatically by the client

---

### author

* Matches `name` from the feed’s profile
* Filled automatically by the client

---

### date

* Date of publication
* Format: `YYYY-MM-DD` (Level 1)
* Generated automatically by the client
* Same-day posts may require a secondary sort rule in higher levels

---

### title (optional)

* Short summary/title of the post
* Used in timeline display
* If omitted, the first line of the body may be used

---

## Post Rules

* Posts are treated as **append-only**
* Existing posts should not be modified after publication
* Each post is self-contained
* No references to external state required
* If `author` does not match `profile:name`, the feed should be treated as suspicious or invalid by higher-level tools

---

## Filenames

### Recommended format

```text
YYYY-MM-DD-short-title
```

Example:

```text
1970-02-10-unix-name-sticking
```

---

### Rules

* Lowercase
* Hyphen-separated
* No spaces
* Keep reasonably short
* Do not rely on filename for identity
* Same-day filename collisions are not resolved by the filename alone in Level 1

---

## Identity Model

A feed has three distinct identifiers:

| Concept        | Source           |
| -------------- | ---------------- |
| Feed identity  | `profile:id`     |
| Author name    | `profile:name`   |
| Directory name | Local filesystem |

Important:

> The canonical identity of a feed is defined only by `profile:id`.

---

## Design Principles

### 1. Human-readable

All files should be easy to:

* read
* edit
* understand

---

### 2. Minimal structure

Avoid complex formats:

* no JSON
* no XML
* no nested structures

---

### 3. Stable identifiers

IDs must:

* remain stable over time
* not depend on filenames

---

### 4. Separation of concerns

* Feed defines data
* Client defines behavior

---

## Limitations (Level 1)

* No support for:

  * replies
  * reactions (votes)
  * threads
  * groups
* No type field for posts yet
* No validation beyond basic parsing

---

## Future Extensions (Not in Level 1)

* `type:` field (e.g. post, reply, reaction)
* `target:` field for replies/reactions
* richer date format (timestamps)
* attachments or media references
* feed metadata extensions

---

## Summary

A feed is:

* a directory
* containing a `profile`
* and a collection of post files

Posts are:

* simple text files
* with a small metadata header
* and a body

This structure keeps the system:

* simple
* transparent
* easy to process
