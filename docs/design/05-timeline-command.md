
# 9social — timeline Command

## Purpose

Display a merged chronological view of posts from all followed feeds.

This is the primary read interface for 9social.

---

## Usage

```sh
9social/timeline
```

---

## Inputs

* No arguments

---

## Files Used

* `/usr/glenda/lib/9social/feeds/`

Each feed directory is expected to contain:

```text
profile
posts/
```

---

## Behavior

### 1. Discover feeds

* List all directories under:

```text
/usr/glenda/lib/9social/feeds/
```

* Each directory represents one feed

---

### 2. Load feed metadata

For each feed:

* Read `profile`
* Extract:

  * `name`
  * `display`

---

### 3. Discover posts

For each feed:

* Read all files under:

```text
posts/
```

* Each file is treated as one post

---

### 4. Parse posts

For each post file:

* Read metadata fields:

  * `id`
  * `author`
  * `date`
  * `title` (optional)

* Extract body text:

  * content after the first blank line

---

### 5. Build post list

Construct a list of posts containing:

* date
* author name (from profile)
* title (if present)
* body (for preview)
* file path (for reference)

---

### 6. Sort posts

* Sort all posts by `date`
* Newest first

Note:

* Level 1 uses date only (`YYYY-MM-DD`)
* If multiple posts share the same date, order is undefined

---

### 7. Render output

For each post, print a summary block:

```text
<date>  <display name>
    <title or derived title>
    <preview text>
```

---

### Title handling

* If `title` exists:

  * display it
* If missing:

  * use first line of body as title

---

### Preview text

* Use the first 1–2 lines of body
* Truncate if necessary
* Do not include full post

---

### Example Output

```text
1973-10-05  Joe Ossanna
    Troff and the phototypesetter
    We got access to a phototypesetter, which opens up some interesting...

1971-07-21  Joe Ossanna
    System becoming useful on PDP-11
    Learning the PDP-7 and now the PDP-11 has been a good exercise...

1971-05-14  Dennis Ritchie
    PDP-11 and thoughts on languages
    We’ve moved the system onto a PDP-11, which gives us more room...
```

---

## Output Format Requirements

* Plain text only
* No ANSI formatting
* Indentation used for structure
* Readable in ACME and terminal

---

## Error Handling

* If a feed is missing `profile`:

  * skip it
* If a post file is malformed:

  * skip it
* Errors should not stop the entire command

---

## Design Rationale

### 1. Simple aggregation

The timeline is constructed entirely from local data.

No network access is required.

---

### 2. Stateless

The command:

* reads data
* produces output

It does not modify any files.

---

### 3. Human-readable output

The output is optimized for:

* terminal viewing
* ACME viewing
* piping into other tools

---

### 4. Minimal parsing

Only basic metadata is required.

No complex parsing or indexing is needed in Level 1.

---

## Limitations (Level 1)

* No pagination
* No filtering
* No grouping
* No threading
* No reactions
* No indexing

---

## Future Extensions (Not in Level 1)

* ACME integration:

  * clickable post entries
  * tag-based actions

* Filtering:

  * by author
  * by date range

* Sorting:

  * time + sequence
  * stable ordering

* Indexing:

  * precomputed timelines
  * faster loading

* Post selection:

  * open full post in new window

---

## Summary

`9social/timeline`:

* reads all local feeds
* merges posts
* sorts by date
* displays summaries

This is the first command that turns stored data into a user-visible experience.
