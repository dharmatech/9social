
## Installing 9social

These are the directions for setting up the 9social client on 9front.

In this example, we'll use github as the location of the user's profile repository.

### Setup ssh

If you're already using 9front and ssh to clone, pull and push to github, you can skip this section.
Otherwise, read on:

Generate an ssh key:

```
auth/rsagen -t 'service=ssh role=client' >key
```

Show key:

```
auth/rsa2ssh key
```

Add key to github:

https://github.com/settings/keys

Add key:

```
cat key >/mnt/factotum/ctl
```

### Download 9social

```
cd
mkdir -p src
cd src
git/clone git@github.com:dharmatech/9social.git
```

If you get this:

```
ssh: unknown host
verify hostkey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
add thumbprint after verification:
	echo 'ssh sha256=uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s server=github.com' >> /usr/lorinda/lib/sshthumbs
ssh: checking hostkey failed: unknown host
git/get: fetch failed: pktline: short read from transport
/bin/git/clone: could not clone repository
failed to clone git@github.com:dharmatech/9social.git: cleaning 9social
```

Run the step that is shown in the output.
For example, with the above output example, you'd run:

```
echo 'ssh sha256=uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s server=github.com' >> /usr/lorinda/lib/sshthumbs
```

Then do the clone again:

```
git/clone git@github.com:dharmatech/9social.git
```

### Setup

Add this line to `$home/lib/profile`:

```
bind -qa $home/src/9social/bin /bin
```

You can add it towards the beginning of the file,
perhaps after the early `bind` lines.

Add this line to `$home/lib/profile` right before `rio`:

```
cat $home/key >/mnt/factotum/ctl
```

so it might look like this:

```
...
plumber
cat $home/key >/mnt/factotum/ctl
rio
...
```

At this point, log out and log back in
in order to have these `profile` lines take effect.

#### Permissions

The scripts should all be executable
when you clone the repository from github.\
However, in case they aren't, you can set the mode on them as follows:

```
cd
cd src/9social/bin/9social
chmod 755 * lib/*
cd
cd src/9social
chmod 755 tests/*
```

#### Tests

At this point, you can run the unit tests if you'd like:

```
cd
cd src/9social
./tests/run.rc
```

If the tests don't pass,
make sure to log out and log in
so your new profile lines take effect.

### Create repository

Create a github repository for your 9social user.

Go to:

https://github.com/new

Repository name: `9social-user-[YOUR-USERNAME]`

So for example `9social-user-rms`

Create a blank `README` file.

### Run `init-self`

Copy your clone address that starts with `git`.

Run `init-self`:

```
9social/init-self git@github.com:dharmatech/9social-user-dharmatech.git
```

### 9social Tutorial

Start acme

Run `9social/Menu` 

Run `9social/Timeline` 

The timeline is empty. So let’s follow some people:

```
9social/follow https://github.com/dharmatech/9social-user-dennis.git
9social/follow https://github.com/dharmatech/9social-user-joe.git
9social/follow https://github.com/dharmatech/9social-user-dharmatech.git
```

`dennis` and `joe` are accounts I'm using for testing.

Run `9social/Timeline` 

The timeline is still empty. Let’s refresh.

Run `9social/refresh`

Now run `9social/Timeline` again.

See a video demo here:

https://www.youtube.com/watch?v=q6qVnlCjcAI
