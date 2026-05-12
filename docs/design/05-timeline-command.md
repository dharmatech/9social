
# 9social — timeline Command

## Purpose

Display a merged chronological view of posts from all followed feeds.

This is the primary read interface for 9social.

---

## Usage

```sh
9social/cmd/timeline
```

---

## Inputs

* No arguments

---

## Files Used

* `$home/lib/9social/feeds/`

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
$home/lib/9social/feeds/
```

* Each directory represents one feed

---

### 2. Load feed metadata

For each feed:

* Read `profile`
* Extract:

  * `name`
  * `display`

* For timeline output, use `display` as the primary author label
* `name` may be kept as fallback metadata if needed
* If `profile` is missing either `name` or `display`, skip the feed

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

Required for Level 1 timeline rendering:

* `date`
* a valid header/body split

Optional for Level 1 timeline rendering:

* `id`
* `author`
* `title`
* body text may be empty

---

### 5. Build post list

Construct a list of posts containing:

* date
* display name (from profile)
* short name (optional fallback metadata)
* title (if present)
* body (for preview)
* file path (for reference)
* filename (for stable sorting)

---

### 6. Sort posts

* Sort all posts by `date`, newest first

Note:

* Level 1 uses UTC ISO 8601 timestamps (`YYYY-MM-DDThh:mm:ssZ`)
* Only the `Z` UTC form is accepted in Level 1
* If multiple posts share the same timestamp, use a deterministic fallback order:

  * feed name
  * then post filename

---

### 7. Render output

For each post, print a summary block:

```text
<date>  <display name>
    <title or derived title>
    <preview text>
```

* Render the full stored UTC timestamp in Level 1

---

### Title handling

* If `title` exists:

  * display it
* If missing:

  * use first line of body as title
* If body is empty, the title line may be left blank
* Leading and trailing whitespace should be trimmed when deriving a title from the body

---

### Preview text

* Use the first 1–2 lines of body
* Preserve line structure rather than collapsing the body to one line
* Trim leading and trailing blank lines
* Truncate if necessary
* In Level 1, a preview may be limited to at most 2 lines and at most 160 characters total
* Do not include full post

---

### Example Output

```text
1973-10-05T16:20:00Z  Joe Ossanna
    Troff and the phototypesetter
    We got access to a phototypesetter, which opens up some interesting...

1971-07-21T19:40:00Z  Joe Ossanna
    System becoming useful on PDP-11
    Learning the PDP-7 and now the PDP-11 has been a good exercise...

1971-05-14T22:43:00Z  Dennis Ritchie
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
* If `profile` is malformed or missing `display`:

  * skip the feed
* If a post file is malformed:

  * skip it
* If a post is missing `date`:

  * skip it
* If `date` is not a valid UTC ISO 8601 timestamp:

  * skip it
* If a post has no body, it may still be shown with an empty preview
* Errors should not stop the entire command
* Skipped feeds and posts may produce short diagnostics on standard error

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

The Level 1 output format is the default timeline presentation, not the only possible one.

---

### 4. Minimal parsing

Only basic metadata is required.

No complex parsing or indexing is needed in Level 1.
The command reads all feeds and posts first, then sorts the combined post list globally.

---



---

## Acme Open Integration

The Acme-oriented `9social/OpenPost` command should support opening posts from either full local paths or canonical post IDs once the local index exists.

This means timeline output can continue to show full paths for transparency, while future timeline variants may show canonical post IDs and still use the same `OpenPost` command.

`timeline` itself should not perform index lookup in Level 1. Opening by ID is handled by `OpenPost` through `9social/lib/post-path`.

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

* Alternate presentations:

  * compact one-line-per-post view
  * expanded social-style view variants

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

`9social/cmd/timeline`:

* reads all local feeds
* merges posts
* sorts by date
* displays summaries

This is the first command that turns stored data into a user-visible experience.
