# acmemail Notes

This note records useful findings from reviewing 9front's Acme mail client while designing Acme-native 9social commands.

## References

Man page:

```rc
man acmemail
```

Source:

```text
/sys/src/cmd/upas/Mail
```

Key files:

```text
/sys/src/cmd/upas/Mail/comp.c
/sys/src/cmd/upas/Mail/win.c
/sys/src/cmd/upas/Mail/mail.h
/sys/src/cmd/upas/Mail/mbox.c
/sys/src/cmd/upas/Mail/mesg.c
```

Build target:

```text
/acme/bin/$objtype/Mail
```

## High-Level Model

`Mail` is a real Acme application, not just a shell command.

It presents three kinds of views:

* mailbox list view
* message view
* composition view

The composition view is the most relevant model for `9social/NewPost`.

In the composition view, the user edits text in an Acme window and then invokes a tag command:

```text
Post
```

`Post` sends the message. For 9social, the analogous command would be something like:

```text
Publish
```

or a more explicit command such as:

```text
9social/publish-draft <draft-path>
```

## Acme Window Control

`Mail` controls Acme windows directly through Acme's file interface.

Important files are described in:

```rc
man 4 acme
```

`Mail` uses `/mnt/wsys`, which is bound to `/mnt/acme` for commands running under Acme.

Important paths:

```text
/mnt/wsys/new/ctl
/mnt/wsys/<id>/ctl
/mnt/wsys/<id>/tag
/mnt/wsys/<id>/body
/mnt/wsys/<id>/event
/mnt/wsys/<id>/addr
/mnt/wsys/<id>/data
```

From `win.c`:

* `wininit` opens `/mnt/wsys/new/ctl` to create a new window
* it reads the new window id from `ctl`
* it writes `name <path>` to name the window
* it opens the window's `event`, `addr`, `data`, and `ctl` files
* `wintagwrite` writes commands into the tag
* `winevent` parses Acme event messages
* `winreturn` returns unhandled events to Acme

## Composition Window Pattern

The relevant function is `compose` in:

```text
/sys/src/cmd/upas/Mail/comp.c
```

It roughly does this:

1. Allocate a composition state object
2. Create a new Acme window with `wininit`
3. Write tag commands:

   ```c
   wintagwrite(c, "Post |fmt ");
   ```

4. Open the body file for writing
5. Write the initial message template
6. Set the selection to the end of the body
7. Start an event loop for that window

The event loop is `compmain`.

It reads Acme events and dispatches tag commands. For composition windows, it recognizes:

```text
Post
Del
```

`Post` calls `postmesg`, which reads the Acme window body and sends the mail.

## Event Handling

Acme event handling is the part that most strongly favors C.

When a program opens a window's `event` file:

* mouse button 2 and button 3 events are reported to the program
* the program must decide whether to handle or return each event
* unhandled events must be written back to the event file in the correct form

`Mail` implements this in C:

```text
winevent
winreturn
compmain
```

This is possible in `rc`, but it is awkward:

* event records need parsing
* event loops are long-running
* unhandled events must be returned correctly
* multiple windows require bookkeeping
* errors in the event loop can make the UI feel broken

## What This Means For 9social

For Level 1, 9social does not need to duplicate all of `Mail`.

A practical rc-based design can be:

* `9social/NewPost` creates a draft file
* it opens the draft in Acme, either by plumbing or by writing to `/mnt/wsys/new/*`
* the draft window/tag includes explicit commands such as:

  ```rc
  9social/publish-draft /usr/glenda/tmp/9social-new-post.<pid>
  9social/cancel-draft /usr/glenda/tmp/9social-new-post.<pid>
  ```

* `publish-draft` performs validation, creates the final post, and commits locally
* `cancel-draft` removes the draft

This gives an Acme-native workflow without an Acme event loop.

## rc vs C Recommendation

Keep the first Acme implementation in `rc`.

`rc` is enough for:

* creating draft files
* plumbing draft files to Acme
* possibly creating a simple Acme window through `/mnt/wsys/new/ctl`
* writing body/tag text
* publishing a draft from an explicit command
* cancelling a draft from an explicit command

C becomes attractive if 9social later wants:

* bare tag commands like `Publish` and `Cancel` handled by a long-running process
* one process managing multiple open draft windows
* direct event-file handling
* automatic window closing on publish/cancel
* robust return of unhandled Acme events

In short:

* `rc` is good for Level 1 Acme workflow
* C is better for a full Acme application like `Mail`

## Related 9social Design

See:

```text
docs/design/08-acme-new-post-command.md
```

The current recommended path is:

1. Keep `9social/cmd/new-post` as the synchronous shell command
2. Add `9social/NewPost` for Acme draft creation
3. Add `9social/publish-draft <draft-path>`
4. Add `9social/cancel-draft <draft-path>`
5. Defer full Acme event-loop integration until there is a strong reason
