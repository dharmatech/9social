# 9social — init-self Command

## Purpose

Initialize the user's own publishing feed.

This command connects a locally stored 9social identity to a Git repository that the user controls.

---

## Usage

```rc
9social/cmd/init-self <git-url>
```

---

## Inputs

* One argument: a Git repository URL

The remote repository is created outside 9social.
For Level 1, the user may create it through a hosting provider web UI, such as GitHub or GitLab.

For GitHub repositories that the user intends to push to from 9front, the SSH clone URL is recommended:

```text
git@github.com:user/repo.git
```

`init-self` does not enforce this. It accepts any URL or path that `git/clone` can clone.

If an HTTPS GitHub URL is provided, `init-self` may print a warning but should still try to clone it.

For GitHub, create the repository with at least one initial file, such as `README`. 9front `git/clone` may not clone an empty GitHub repository.

---

## Files Used

```text
$home/lib/9social/
    self/
```

After initialization:

```text
$home/lib/9social/self/
    profile
    following
    posts/
```

---

## Behavior

### 1. Validate arguments

If the command is not given exactly one argument, print:

```text
usage: 9social/cmd/init-self <git-url>
```

and exit with failure.

Trim leading and trailing whitespace from the URL.
If the resulting URL is empty, fail.

---

### 2. Ensure local state directory

Ensure this directory exists:

```text
$home/lib/9social
```

If it cannot be created, fail.

---

### 3. Handle an existing self directory

If `$home/lib/9social/self` does not exist, continue with a normal clone.

If `$home/lib/9social/self` exists and is already a Git repository, fail with a clear diagnostic. Level 1 does not support replacing or reconfiguring an existing initialized self feed.

If `$home/lib/9social/self` exists and is not a Git repository, `init-self` may auto-migrate it only when it contains the pre-init follow list:

```text
$home/lib/9social/self/following
```

and no other regular files. Empty directories may be ignored.

If unknown regular files exist under pre-init `self/`, fail and tell the user to move or remove them manually. This check is intentionally limited to regular files; empty directories may be ignored.

When auto-migrating, save `following` aside, replace the pre-init `self/` with the cloned repository, then restore or merge `following` into the clone.

The saved file should live outside `self/`, for example:

```text
$home/lib/9social/following.<pid>.tmp
```

Remove the temporary file after a successful restore or merge. If migration fails, leave diagnostics clear enough that the user can recover the saved follow list manually.

---

### 4. Clone the repository

Clone the provided URL into:

If the URL begins with `https://github.com/`, print a warning that the SSH URL is usually better for repositories the user intends to push to from 9front. Continue anyway.

```text
$home/lib/9social/self
```

If cloning fails, remove the partially created `$home/lib/9social/self`, report the failure, and exit.

This cleanup is safe when `self/` did not exist before cloning. If `init-self` is migrating a pre-init `self/following`, it must keep the saved follow list outside the clone path until cloning succeeds.

---

### 5. Create or validate feed structure

Inside `$home/lib/9social/self`, ensure:

```text
profile
following
posts/
```

`init-self` supports both empty repositories and repositories that already contain a valid 9social feed.

Rules:

* If `profile` is missing, create it
* If `profile` already exists, validate it and do not replace it
* If `profile` is malformed, fail
* If `posts/` is missing, create it
* When creating `posts/`, also create `posts/.keep` so Git can track the directory
* If `posts/` already exists, leave it alone
* If `following` is missing, create it as an empty file
* If `following` was saved from a pre-init self directory, merge it with any cloned `following`, remove blank lines, deduplicate, and sort
* Commit the migrated `following` only if the final merged file differs from the cloned repository's original `following`
* If `profile`, `following`, and `posts/` already exist and are valid, make no changes

---

## Profile Generation

When creating a new `profile`, `init-self` generates a globally unique user ID.

### User ID Format

```text
9social:user:<uuid>
```

Example:

```text
9social:user:550e8400-e29b-41d4-a716-446655440000
```

The UUID should be generated randomly.
Level 1 uses a script helper:

```rc
9social/lib/id/uuid
```

That helper prints one UUID v4. It may be implemented in `rc` using `/dev/random`, `dd`, `xd`, and `awk`.

---

### Profile Format

```text
id: 9social:user:<uuid>
name: <short-name>
display: <display-name>
```

For example:

```text
id: 9social:user:550e8400-e29b-41d4-a716-446655440000
name: dharmatech
display: Dharmatech
```

---

`init-self` does not write the repository URL into `profile`.
The Git remote records transport location; `profile:id` remains the canonical feed identity even if the repository moves or is mirrored.

---

## Name and Display Values

Level 1 should keep setup simple.

Recommended behavior:

* Derive a candidate `name` from the repository URL
* `display` defaults to the same value as `name`

Name derivation rules:

* Trim leading and trailing whitespace from the URL
* Remove trailing slashes
* For path-like and HTTPS URLs, take the text after the final `/`
* For SSH SCP-style URLs such as `git@github.com:user/repo.git`, take the text after the final `:`
* Strip a trailing `.git` if present
* Strip a leading `9social-user-` if present
* Require the result to be non-empty
* Require the result to match `^[a-z0-9][a-z0-9-]*$`

If no valid `name` can be derived, fail with a clear diagnostic.

For example:

```text
https://github.com/dharmatech/9social-user-dharmatech.git
```

produces:

```text
name: dharmatech
display: dharmatech
```

The generated `display` value is only a default.
The user may manually edit `profile` before pushing if they want a more polished display name.

Future versions may allow interactive prompts or command-line flags to override these values.

---

## Profile Validation

If `profile` already exists, validate it before making any other feed changes.

Level 1 validation requires:

* `profile` is a regular file
* it contains an `id:` field
* it contains a `name:` field
* it contains a `display:` field
* `id:` matches `9social:user:<uuid>`
* `name:` is non-empty after trimming whitespace
* `display:` is non-empty after trimming whitespace

The UUID portion of `id:` must have the usual dashed lowercase hexadecimal shape:

```text
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Level 1 validation does not require:

* a specific field order
* exactly three fields
* rejecting unknown fields
* checking UUID version or variant bits beyond the UUID shape

If the existing profile is missing required fields or has an invalid `id`, fail.

---

## Git Integration

After creating or validating the feed structure, commit any files created by `init-self`.

Rules:

* Commit locally only
* Do not push
* Track created paths explicitly during setup
* Add only files created or migrated by `init-self`
* If `posts/` was created, add `posts/.keep`
* If `following` was created or changed by migration, add `following`
* Do not commit `following` if merge/dedupe/sort leaves it unchanged
* Pass the created or migrated path list to both `git/add` and `git/commit`
* Leave unrelated repository state alone
* If nothing was created, exit successfully without committing

Suggested commands:

```rc
git/add <created-path> ...
git/commit -m 'init 9social self feed' <created-path> ...
```

Suggested commit message for initial structure:

```text
init 9social self feed
```

Suggested commit message when importing a pre-init follow list into an otherwise existing feed:

```text
follow: import following
```

If `git/add` or `git/commit` fails, leave created files in place and report the failure.

---

## Error Handling

Abort with a diagnostic if:

* the URL argument is missing or empty
* `$home/lib/9social` cannot be created
* `$home/lib/9social/self` already exists as an initialized Git repository
* the repository cannot be cloned
* partial clone cleanup fails
* `posts/` cannot be created
* `profile` cannot be created
* `following` cannot be created or migrated
* an existing `profile` is malformed
* Git add or commit fails

---

## Non-Goals

Level 1 does not include:

* creating the remote repository
* provider-specific APIs
* GitHub/GitLab authentication setup
* pushing after initialization
* reconfiguring an existing self feed
* supporting a self feed outside `$home/lib/9social/self`
* adding the user's own feed URL to `$home/lib/9social/self/following`

---

## Future Considerations

A future client may offer an explicit follow-self action that adds the user's own feed URL to `$home/lib/9social/self/following`.

This should be opt-in because following oneself is a social graph choice, while `init-self` is publishing setup.

---

## Summary

`9social/cmd/init-self` prepares the user's own feed for publishing.

It clones a user-controlled remote repository into `$home/lib/9social/self`, creates the Level 1 feed structure, generates the canonical 9social user ID if needed, and commits the initial local state without pushing.
