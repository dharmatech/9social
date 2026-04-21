
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

---

## Files Used

* `/usr/glenda/lib/9social/following`
* `/usr/glenda/lib/9social/`

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

   * If `/usr/glenda/lib/9social/` does not exist:

     * create it

4. **Ensure following file exists**

   * If `/usr/glenda/lib/9social/following` does not exist:

     * create it

5. **Check for duplicates**

   * If the URL already exists as a full line in `following`:

     * do nothing
     * exit successfully

6. **Append URL**

   * If `following` exists and does not end with a newline:

     * write one newline first

   * Add the URL as a new line at the end of the file

---

## Output

* **Success:** no output
* **Failure:** print a short error message to standard error

---

## Example Result

After running:

```sh
9social/follow https://github.com/dharmatech/9social-user-dennis.git
```

The file:

```text
/usr/glenda/lib/9social/following
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

## Future Extensions (Not in Level 1)

* URL validation
* Optional alias names
* Immediate clone option (`follow --fetch`)
* Support for local paths
* `9social/unfollow`
