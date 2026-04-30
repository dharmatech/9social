

Here's an example script:

`/usr/glenda/docs/journal/2026-04-15/txt-headings/acme-cursor-position.rc`

```
#!/bin/rc

result=`{
	cd /mnt/acme/$winid
	{
		echo 'addr=dot' > ctl
		cat addr
	} < addr
}

echo $result | awk '{print $1}'
```

- Have the script name `acme-cursor-position.rc` in the window tag
- Left-click somewhere in an acme window to place the cursor
- Middle-click the script name `acme-cursor-position.rc`
- The script will get the cursor position
- This script is meant to be called by other scripts
  which would like to find out the current cursor position
  in the current window.

