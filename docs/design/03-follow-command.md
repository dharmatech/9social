
# 9social — follow Command

## Purpose

Add a remote feed to the user's following list.

This command **does not** clone or fetch the repository.  
That is handled by `9social/refresh`.

---

## Usage

```sh
9social/follow <url>
```

### Example

```sh
9social/follow https://github.com/dharmatech/9social-user-dennis.git
```

---

## Inputs

* One argument: a remote repository URL
* After trimming leading/trailing whitespace, the URL must not be empty
* At Level 1, the command accepts the URL string as given after trimming
* It does not check whether the URL is reachable or whether it is a valid Git remote

---

## Files Used

* `$home/lib/9social/following`
* `$home/lib/9social/`

---

## Behavior

1. **Validate input**

   * If no argument is provided:

     * print an error message
     * exit with failure

   * If the argument becomes empty after trimming whitespace:

     * print an error message
     * exit with failure

2. **Normalize URL**

   * Trim leading/trailing whitespace
   * Do not otherwise modify the URL (Level 1)

3. **Ensure local state path exists**

   * If `$home/lib/9social/` does not exist:

     * create it
     * if creation fails, print a short error message and exit with failure

4. **Ensure following file exists**

   * If `$home/lib/9social/following` does not exist:

     * create it
     * if creation fails, print a short error message and exit with failure

5. **Check for duplicates**

   * If the URL already exists as a full line in `following`:

      * do nothing
      * exit successfully

   * Duplicate matching is performed after trimming the input URL
   * Different URL spellings remain distinct in Level 1

6. **Append URL**

   * If `following` exists and does not end with a newline:

     * write one newline first

   * Add the URL as a new line at the end of the file
   * If the append fails, print a short error message and exit with failure

---

## Output

* **Success:** no output
* **Failure:** print a short error message to standard error

Suggested Level 1 error messages:

* `usage: 9social/follow <url>`
* `9social/follow: empty url`
* `9social/follow: cannot create $home/lib/9social`
* `9social/follow: cannot create $home/lib/9social/following`
* `9social/follow: cannot update $home/lib/9social/following`

---

## Example Result

After running:

```sh
9social/follow https://github.com/dharmatech/9social-user-dennis.git
```

The file:

```text
$home/lib/9social/following
```

may contain:

```text
https://github.com/dharmatech/9social-user-dennis.git
```

---

## Notes

* This command only modifies local configuration
* It does not access the network
* It does not validate repository contents
* It is safe to run multiple times with the same URL
* The `following` file is a strict list of repository URLs, one per line
* Blank lines and comment lines are not part of the Level 1 format
* In Level 1, `follow` records transport locations, not canonical feed identity
* Files and directories are created with normal user defaults for the running environment

---

## Design Rationale

The `follow` command is intentionally minimal.

Responsibilities are separated:

| Command            | Responsibility          |
| ------------------ | ----------------------- |
| `9social/follow`   | Record intent to follow |
| `9social/refresh`  | Fetch and update feeds  |
| `9social/timeline` | Display posts           |

This keeps each command:

* simple
* composable
* easy to reason about

This also means a feed may be reachable at multiple URLs.
At Level 1, `follow` does not reconcile those URLs against the feed's `profile` identity.
That reconciliation, if added later, belongs in higher-level refresh or indexing logic rather than in this command.

---

## Non-Goals For Level 1

* No URL canonicalization beyond trimming leading/trailing whitespace
* No network or repository reachability checks
* No inspection of remote repository contents
* No validation of feed structure or `profile`
* No reconciliation between repository URLs and canonical feed identity

---

## Future Extensions (Not in Level 1)

* URL validation
* Optional alias names
* Immediate clone option (`follow --fetch`)
* Support for local paths
* `9social/unfollow`
