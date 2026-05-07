
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

Add this to `$home/lib/profile` 

Add it around line 3, after the other two `bind` lines.

```
bind -qa $home/src/9social/bin /bin
cat $home/key >/mnt/factotum/ctl
```

Make sure all the 9social scripts are executable:

```
cd
cd src/9social/bin/9social
chmod 755 * lib/*
cd
```


### create repository

Create a github repository for your 9social user.

Go to:

https://github.com/new

Repository name: `9social-user-[YOUR-USERNAME]`

So for example `9social-user-rms`

Create a blank `README` file.

### Run `init-self`

Copy your clone address that starts with `git` .

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

- `9social/timeline` : layout
    
    ![image.png](attachment:c859c186-0721-4fb9-a2b8-5d6ae0e1ba47:image.png)
    
    - should `9social/timeline` implement word wrap?
        - Is there a facility in 9front to implement this?
            - Some shell command or a combination of them?
    - The indentation looks good, however, it looks weird when a line is too long
        - Consider: instead of indentation, use a horizontal line
    - Should we list the posts in ascending order?
        - I.e. newest at the bottom?

That is all you have to do to follow and read others posts.
If you would like to create your own posts, do the following.
