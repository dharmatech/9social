
# 9social — Plain Text and Markdown Compatibility

## Purpose

Define how post bodies are represented in 9social, and clarify the role of Markdown-style formatting.

---

## Core Principle

> Post bodies in 9social are plain text.

Posts must be:
- readable without any rendering
- editable using standard text tools
- compatible with Plan 9 environments (e.g. ACME)

---

## Design Goals

Post content should:

- be easy to read in raw form
- be easy to write in simple editors
- avoid reliance on complex formatting systems
- remain compatible with richer clients on other platforms

---

## Markdown Compatibility

Authors may use **Markdown-compatible conventions**, provided that:

- the text remains readable without rendering
- the formatting does not depend on a specific Markdown parser
- no required feature depends on Markdown support

---

## Recommended Markdown-Compatible Features

The following conventions are encouraged because they work well in plain text:

### Headings

```text
# Section Title
## Subsection
```

---

### Lists

```text
- Item one
- Item two

1. First
2. Second
```

---

### Code blocks

Fenced:

```text
```

example code

```
```

Indented:

```text
    example code
```

---

### Block quotes

```text
> quoted text
```

---

### Tables (simple)

```text
Name    Value
----    -----
foo     123
bar     456
```

---

## Hyperlinks

### Problem

Standard Markdown link syntax:

```text
[description](https://example.com)
```

is difficult to read in plain text and awkward in ACME.

---

### Preferred Style: Footnote Links

Use a reference-style format:

```text
Ken’s paper is worth reading [1].

[1] https://example.org/ken-paper
```

---

### Advantages

* clean and readable prose
* URLs do not clutter sentences
* works well in plain text
* easy for ACME to handle
* compatible with richer clients

---

### Alternative Styles

Inline raw URLs are also acceptable:

```text
https://example.org/ken-paper
```

or:

```text
See: https://example.org/ken-paper
```

---

## Non-Goals (Level 1)

9social does **not** require:

* full Markdown support
* a specific Markdown flavor (CommonMark, etc.)
* HTML rendering
* rich text formatting

---

## Client Behavior

Clients may:

* render Markdown-style formatting for display
* enhance readability (e.g. clickable links, formatted headings)

Clients must:

* work correctly with plain text
* not depend on Markdown rendering for correctness

---

## Design Constraint

> A post must remain understandable when viewed as plain text only.

If formatting reduces readability in raw form, it should be avoided.

---

## Rationale

This approach ensures:

### 1. Compatibility with Plan 9

* works naturally in ACME and other text tools
* no special rendering required

---

### 2. Portability

* other platforms can render content more richly
* no dependency on a specific rendering engine

---

### 3. Longevity

* plain text is durable
* no reliance on evolving markup standards

---

### 4. Simplicity

* easy to implement parsers
* minimal processing required

---

## Summary

* Post bodies are plain text
* Markdown-style conventions are allowed but optional
* readability without rendering is required
* footnote-style links are preferred over inline Markdown links

> Plain text is the baseline. Markdown is a compatibility layer, not a dependency.

