# Testing

9social tests are rc scripts under `tests/`. Run them inside 9front.

## Full test suite

From 9front:

```rc
/usr/glenda/src/9social/tests/run.rc
```

From Linux/Codex, use drawterm:

```sh
/home/dharmatech/src/drawterm/drawterm -h 127.0.0.1 -u glenda -a 127.0.0.1 -G -c '/usr/glenda/src/9social/tests/run.rc'
```

## Focused tests

When changing one script, run the closest focused test first. Then run the full suite before considering the change complete.

```text
bin/9social/cmd/follow                 tests/follow.rc
bin/9social/cmd/refresh                tests/refresh.rc
bin/9social/cmd/init-self              tests/init-self.rc
bin/9social/cmd/new-post               tests/new-post.rc, tests/new-post-editor.rc
bin/9social/NewPost                manual Acme smoke test; related automated tests cover helpers and publishing
bin/9social/Draft/Publish                tests/publish.rc
bin/9social/cmd/reply                  tests/reply.rc
bin/9social/Draft/Cancel                 tests/cancel.rc
bin/9social/Post/Reply                  manual Acme smoke test; related helpers have focused tests
bin/9social/cmd/like                   tests/like.rc
bin/9social/Post/Like                   tests/Like.rc
bin/9social/Post/Delete                 tests/delete.rc
bin/9social/Post/Update                 tests/update.rc
bin/9social/cmd/push                   tests/push.rc
bin/9social/cmd/timeline               tests/timeline.rc
bin/9social/Timeline               tests/Timeline.rc
bin/9social/cmd/show-threads            tests/show-threads.rc, tests/render-threads.rc
bin/9social/ShowThreads            tests/ShowThreads.rc
bin/9social/OpenPost              tests/OpenPost.rc
```

Helper tests generally follow helper names:

```text
bin/9social/lib/check-self         tests/check-self.rc
bin/9social/lib/draft/valid.awk        tests/valid-draft.rc
bin/9social/lib/draft/slug.awk         tests/draft-slug.rc
bin/9social/lib/valid-profile.awk  tests/valid-profile.rc
bin/9social/lib/encode-id          tests/encode-id.rc
bin/9social/lib/mk-temp-file       tests/mk-temp-file.rc
bin/9social/lib/post/meta.awk          tests/post-meta.rc
bin/9social/lib/post/path          tests/post-path.rc
bin/9social/lib/post/id.awk            tests/post-id.rc
bin/9social/lib/post/title         tests/post-title.rc
bin/9social/lib/post/check.awk         tests/check-post.rc
bin/9social/lib/liked-post         tests/liked-post.rc
bin/9social/lib/render/threads     tests/render-threads.rc
bin/9social/lib/draft/reply        tests/reply-draft.rc
```

## Rule of thumb

* If changing a command, run its focused test.
* If changing a helper, run the helper test and focused tests for direct callers.
* If changing shared format, profile, index, post parsing, or Git behavior, run the full suite.
* If changing an Acme-only command, run automated helper tests plus a manual Acme smoke test.

## Workflow tests

For broader non-interactive coverage, use simulated users and local repositories rather than real remote services.

See `docs/meta/simulated-multi-user-testing.md`.

## Acme smoke tests

Some behavior depends on the live Acme filesystem and is intentionally not fully mocked. For commands such as `NewPost`, `Reply`, `Timeline`, `ShowThreads`, `Like`, `Delete`, and `Update`, use Acme manually after the focused automated tests pass.

Examples:

* Middle-click `9social/NewPost`, edit the draft, then middle-click `9social/Draft/Publish`.
* Middle-click `9social/Timeline` or `9social/ShowThreads`, place the cursor on a post reference, then middle-click `9social/OpenPost`.
* Open another user's post and verify the tag commands such as `9social/Post/Reply` and `9social/Post/Like`.
