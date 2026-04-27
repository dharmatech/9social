# 9front / Codex working context

I have a 9front system running inside this stack:

`thinkpad : Windows 11 : WSL : Ubuntu : QEMU : 9front` 

The 9front root filesystem is exported from 9front with:

`aux/listen1 -t tcp!*!17021 /bin/exportfs -r /`

and mounted in Ubuntu with plan9port `9pfuse`:

`/home/dharmatech/src/plan9port/bin/9pfuse 'tcp!127.0.0.1!17021' ~/mnt/9front` 

So Codex can inspect and edit the 9front filesystem at:

`~/mnt/9front`

The same path inside 9front is `/`.

For running commands inside 9front, use `drawterm`:

`/home/dharmatech/src/drawterm/drawterm -h 127.0.0.1 -u glenda -a 127.0.0.1 -G -c '<command>'` 

For an interactive shell inside 9front:

`/home/dharmatech/src/drawterm/drawterm -h 127.0.0.1 -u glenda -a 127.0.0.1 -G -c rc`

Note: you will likely have to run `drawterm` outside the sandbox. Feel free to do so.

Examining files through the 9pfuse mount at `~/mnt/9front` can sometimes be a little slow.
So you might prefer `drawterm` for looking at files.

Useful 9front source locations:

- `/bin` contains scripts and binaries.
- `/sys/src` contains the operating system source.
- `/sys/src/cmd` contains command source.
- Man pages are available with `man`, for example `man webfs`, `man hget`, `man ndb`.
- Use `walk` inside 9front for recursive file listing.
- Use `g 'pattern'` inside a source directory to recursively search source files.

Prefer running filesystem-heavy searches inside 9front with `walk`/`g`, not from Ubuntu over 9pfuse, because the mount can be slow.

Our project directory in 9front is at: `/usr/glenda/src/9social` 

There are design documents at `/usr/glenda/src/9social/docs/design` 

Important operational notes:

- Starting `webfs` may be needed before using `hget`.
- If files exist in `/mnt/web`, `webfs` is running.
- `webfs` can be started with `webfs`.
- `webfs -d` enables debug logging.
- `webfs -T timeout_ms` changes the request timeout.
- To change timeout on a running webfs: `echo timeout 60000 >/mnt/web/ctl`.

Do not modify system files directly unless I ask.

To begin with, please try to run a test command using `drawterm` outside the sandbox.
Let me know if you're able to do so.

# acme documentation

Our project, `9social` will be designed for use within `acme`.
To understand `acme`, read the paper here:

    /sys/doc/acme/acme.ms

See also the man page:

    man acme

The source code to acme is in:

    /sys/src/cmd/acme

## Mail

There is a mail client built for acme.
The source code is here:

/sys/src/cmd/upas/Mail

That's a good application to review to understand one appraoch to integration with acme.

# FQA

The FQA is general documentation for 9front.

See the *.ms files in:

/sys/src/fqa.9front.org

