#!/bin/awk -f
# Extract the metadata header from a post file.
#
# Reads key-value lines before the first blank line and prints them as
# tab-separated key and value pairs, leaving the post body untouched.
BEGIN {
	if(ARGC != 2){
		print "usage: 9social/lib/post/meta.awk <post-file>" > "/fd/2"
		failed = 1
		exit 1
	}
}

/^[ 	]*$/ {
	done = 1
	next
}

done {
	next
}

{
	if($0 !~ /^[A-Za-z][A-Za-z0-9-]*:[ 	]*/){
		print "post-meta: malformed header line" > "/fd/2"
		failed = 1
		exit 1
	}
	key = $0
	sub(/:.*/, "", key)
	value = $0
	sub(/^[A-Za-z][A-Za-z0-9-]*:[ 	]*/, "", value)
	sub(/[ 	]*$/, "", value)
	n++
	keys[n] = key
	values[n] = value
}

END {
	if(failed)
		exit 1
	for(i = 1; i <= n; i++)
		print keys[i] "	" values[i]
}
