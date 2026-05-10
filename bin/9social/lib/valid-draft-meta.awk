#!/bin/awk -f /bin/9social/lib/id.awk -f
# Validate draft sidecar metadata and print type and target.

function trim(s){
	gsub(/^[ \t]+/, "", s)
	gsub(/[ \t]+$/, "", s)
	return s
}

BEGIN {
	FS = ": "
}

function failmeta(msg){
	print "publish-draft: bad metadata: " msg > "/fd/2"
	failed = 1
	exit 1
}

index($0, ": ") == 0 { failmeta("malformed field") }

{
	key = $1
	val = trim(substr($0, index($0, ": ") + 2))
	if(key == "type"){
		if(type != "")
			failmeta("duplicate type")
		type = val
	} else if(key == "target"){
		if(target != "")
			failmeta("duplicate target")
		target = val
	} else
		failmeta("unknown field " key)
}

END {
	if(failed)
		exit 1
	if(type == "")
		failmeta("missing type")
	if(target == "")
		failmeta("missing target")
	if(type != "reply")
		failmeta("unsupported type")
	if(! is_post_id(target))
		failmeta("malformed target")
	print type
	print target
}
