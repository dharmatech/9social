
# 9social — refresh Command

## Purpose

Synchronize all followed feeds.

This includes:
- cloning feeds that are not yet present locally
- updating feeds that already exist locally

---

## Usage

```sh
9social/cmd/refresh
```

---

## Inputs

* No arguments

---

## Files Used

* `$home/lib/9social/self/following`
* `$home/lib/9social/feeds/`
* `$home/lib/9social/index/`

---

## Behavior

1. **Ensure base directories exist**

   * If `$home/lib/9social/feeds/` does not exist:

     * create it
     * if creation fails, print a short error message and exit with failure

2. **Read following list**

   * If `$home/lib/9social/self/following` does not exist:

     * skip feed updates
     * continue to index rebuild

   * Open `$home/lib/9social/self/following`
   * If the file cannot be read:

     * print a short error message
     * exit with failure

   * For each non-empty line:

     * treat the line as a remote repository URL

   * If the file exists but contains no URLs:

     * skip feed updates
     * continue to index rebuild

3. **Process each URL**

   For each URL:

   ### 3.1 Derive local directory name

   * Extract repository basename from URL

   Example:

   ```text
   https://github.com/dharmatech/9social-user-dennis.git
   ```

   → local name:

   ```text
   9social-user-dennis
   ```

   * Strip trailing `.git` if present

   ### 3.2 Determine local path

   ```text
   $home/lib/9social/feeds/<name>
   ```

   ### 3.3 Clone or update

   * If directory does not exist:

     * clone repository into the directory

     Example:

     ```sh
     git/clone <url> $home/lib/9social/feeds/<name>
     ```

   * If directory exists:

     * if it is a valid Git repository:

       * change into the repository directory
       * run:

       ```sh
       git/pull
       ```

     * if it is not a valid Git repository:

       * print a short error message
       * skip that feed

   ### 3.4 Continue after per-feed failures

   * If clone or update fails for one feed:

     * print a short error message
     * continue processing the remaining feeds

   * If two URLs would map to the same local feed directory name:

     * print a short error message for the collision
     * skip the later feed
     * continue processing the remaining feeds

4. **Rebuild local index**

   After feed processing, run:

   ```sh
   9social/lib/index/rebuild
   ```

   `refresh` should run `reindex` even if there is no `following` file or the following list is empty. This keeps the user's own `self/posts` indexed.

   Warnings from `reindex`, such as malformed skipped posts, may be printed directly.

   If `reindex` fails structurally, print a short error and remember the failure.

5. **Exit status**

   * If all feeds refresh successfully and indexing succeeds:

     * exit successfully

   * If one or more feeds fail, or indexing fails structurally:

     * exit with failure after processing all URLs and attempting index rebuild

---

## Output

* On success, progress output is allowed but should stay short and readable
* Errors should be printed if:

  * feeds directory cannot be created
  * clone fails
  * update fails
  * following file cannot be read
  * an existing feed path is not a Git repository

Suggested Level 1 progress messages:

* `clone <url>`
* `update <name>`

Suggested Level 1 error messages:

* `9social/cmd/refresh: cannot create $home/lib/9social/feeds`
* `9social/cmd/refresh: cannot read $home/lib/9social/self/following`
* `9social/cmd/refresh: clone failed: <url>`
* `9social/cmd/refresh: update failed: <name>`
* `9social/cmd/refresh: not a git repository: <path>`
* `9social/cmd/refresh: name collision: <name>`

---

## Example

### following file

```text
https://github.com/dharmatech/9social-user-dennis.git
https://github.com/dharmatech/9social-user-joe.git
```

### After running

```sh
9social/cmd/refresh
```

### Resulting directories

```text
$home/lib/9social/feeds/
    9social-user-dennis/
    9social-user-joe/
```

---

## Notes

* This command performs all network operations
* It is safe to run multiple times
* It should be idempotent:

  * running it repeatedly should not create duplicates
* Progress messages are optional, but success should remain easy to scan
* A missing or empty `following` file is not an error in Level 1
* `refresh` still rebuilds the local index when there are no followed feeds

---

## Design Rationale

The `refresh` command separates **data transport** from other concerns.

| Command            | Responsibility               |
| ------------------ | ---------------------------- |
| `9social/cmd/follow`   | Record which feeds to follow |
| `9social/cmd/refresh`  | Fetch/update feed data       |
| `9social/cmd/timeline` | Read and display data        |

This separation ensures:

* simpler commands
* easier debugging
* clearer mental model

---

## Limitations (Level 1)

* No handling of name collisions

  * if two repos share the same basename, the command should report an error and continue
  * collision resolution is not implemented in Level 1

* No validation of feed contents

  * assumes repo contains valid `profile` and `posts/`

* No incremental indexing

  * this command only updates repositories

---

## Future Extensions (Not in Level 1)

* Unique local naming (e.g. suffix with hash)
* Mapping file:

  * URL → local path → feed ID
* Partial or shallow clone
* Archive feed support
* Parallel fetching
* Progress reporting
* Error recovery and retry logic
