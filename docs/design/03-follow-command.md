
# 9social — follow Command

## Purpose

Add a remote feed to the user's following list.

This command **does not** clone or fetch the repository.  
That is handled by `9social/cmd/refresh`.

---

## Usage

```sh
9social/cmd/follow <url>
```

### Example

```sh
9social/cmd/follow https://github.com/dharmatech/9social-user-dennis.git
```

---

## Inputs

* One argument: a remote repository URL
* After trimming leading/trailing whitespace, the URL must not be empty
* At Level 1, the command accepts the URL string as given after trimming
* It does not check whether the URL is reachable or whether it is a valid Git remote

---

## Files Used

* `$home/lib/9social/self/following`
* `$home/lib/9social/self/`
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

4. **Ensure self path exists**

   * If `$home/lib/9social/self/` does not exist:

     * create it
     * if creation fails, print a short error message and exit with failure

   This may create a minimal pre-init `self/` directory containing only `following`.

5. **Update following file**

   * Add the URL to `$home/lib/9social/self/following`
   * Remove blank lines
   * Remove duplicate lines
   * Sort the file lexically
   * If the update fails, print a short error message and exit with failure

   Duplicate matching is performed after trimming the input URL. Different URL spellings remain distinct in Level 1.

   If the normalized file contents are unchanged, exit successfully without committing.

6. **Commit if self is initialized**

   * If `$home/lib/9social/self/.git` exists and the `following` file changed, commit only `following`:

   ```rc
   git/add following
   git/commit -m 'follow: <url>' following
   ```

   The commit message should use the normalized URL directly. Example:

   ```text
   follow: git@github.com:dharmatech/9social-user-dennis.git
   ```

   * If `self/` is not a Git repository, do not commit. This is the reader/pre-init mode.
   * `follow` does not push.

---

## Output

* **Success:** no output
* **Failure:** print a short error message to standard error

Suggested Level 1 error messages:

* `usage: 9social/cmd/follow <url>`
* `9social/cmd/follow: empty url`
* `9social/cmd/follow: cannot create $home/lib/9social`
* `9social/cmd/follow: cannot create $home/lib/9social/self/following`
* `9social/cmd/follow: cannot update $home/lib/9social/self/following`

---

## Example Result

After running:

```sh
9social/cmd/follow https://github.com/dharmatech/9social-user-dennis.git
```

The file:

```text
$home/lib/9social/self/following
```

may contain:

```text
https://github.com/dharmatech/9social-user-dennis.git
```

---

## Notes

* This command modifies the public follow list in `self/following`
* It does not access the network
* It does not validate repository contents
* It is safe to run multiple times with the same URL
* If the URL is already present, the command should make no commit
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
| `9social/cmd/follow`   | Record intent to follow |
| `9social/cmd/refresh`  | Fetch and update feeds  |
| `9social/cmd/timeline` | Display posts           |

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
