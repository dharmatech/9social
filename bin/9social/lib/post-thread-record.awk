#!/bin/awk -f /bin/9social/lib/id.awk -f
# Read one post file and emit one normalized thread record.

BEGIN {
	postpath = ARGV[1]
}

/^[ \t]*$/ { done = 1; next }
done { next }

{
	if($0 !~ /^[A-Za-z][A-Za-z0-9-]*:[ \t]*/)
		exit 1
	key = $0
	sub(/:.*/, "", key)
	value = $0
	sub(/^[A-Za-z][A-Za-z0-9-]*:[ \t]*/, "", value)
	sub(/[ \t]*$/, "", value)
	data[key] = value
}

END {
	if(! is_post_id(data["id"]))
		exit 0
	target = ""
	if((data["type"] == "reply" || data["type"] == "like") && is_post_id(data["target"]))
		target = data["target"]
	print data["id"] "\t" data["date"] "\t" data["author"] "\t" data["title"] "\t" data["type"] "\t" target "\t" postpath
}
