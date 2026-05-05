#!/bin/awk -f
# Read one post file and emit one normalized thread record.

BEGIN {
	canon = "^9social:post:[0-9a-f-]+:[0-9a-f-]+$"
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
	if(data["id"] !~ canon)
		exit 0
	target = ""
	if((data["type"] == "reply" || data["type"] == "like") && data["target"] ~ canon)
		target = data["target"]
	print data["id"] "\t" data["date"] "\t" data["author"] "\t" data["title"] "\t" data["type"] "\t" target "\t" postpath
}
