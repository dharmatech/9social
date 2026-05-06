# Onboarding

Start here:

1. Read `docs/meta/intro.md`.
2. Read `docs/meta/testing.md`.
3. Read the core design docs:
   * `docs/design/00-overview.md`
   * `docs/design/01-filesystem-layout.md`
   * `docs/design/02-feed-format.md`

Then read the design doc for the command or feature being changed.

## Useful Meta References

For 9front shell and rc details, read as needed:

* `docs/meta/rc-learning.md`

For Acme work, read as needed:

* `docs/meta/acme-window-cursor-position.md`
* `docs/meta/acmemail.md`

For testing, especially before changing scripts, read:

* `docs/meta/testing.md`

## Working Pattern

When changing code:

1. Read the relevant script and nearby helpers.
2. Read the relevant design document.
3. Make the smallest coherent change.
4. Run the focused test for the changed script or helper.
5. Run the focused tests for direct callers when changing a helper.
6. Run the full test suite before considering the change complete.
7. For Acme-only behavior, also run a manual Acme smoke test.
