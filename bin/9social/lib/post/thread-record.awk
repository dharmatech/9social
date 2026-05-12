#!/bin/awk -f /bin/9social/lib/id/common.awk -f
# Emit one tab-separated thread record for a post file.

BEGIN {
	postpath = ARGV[1]
}

function clean_field(s)
{
	gsub(/\t/, "    ", s)
	return s
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
	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
		data["id"],
		data["date"],
		clean_field(data["author"]),
		clean_field(data["title"]),
		data["type"],
		target,
		postpath
}
