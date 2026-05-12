#!/bin/awk -f /bin/9social/lib/id/common.awk -f

# Print the canonical post id from a post file,
# validating that
# exactly one valid id field
# appears before the post body.

BEGIN {
	if(ARGC != 2){
		print "usage: post-id <post-file>" > "/fd/2"
		failed = 1
		exit 1
	}
}

/^[ \t]*$/ {
	done = 1
	next
}

done {
	next
}

/^id:[ \t]*/ {
	value = $0
	sub(/^id:[ \t]*/, "", value)
	sub(/[ \t]*$/, "", value)
	if(id != ""){
		print "post-id: duplicate id" > "/fd/2"
		failed = 1
		exit 1
	}
	id = value
	next
}

END {
	if(failed)
		exit 1
	if(id == ""){
		print "post-id: missing id" > "/fd/2"
		exit 1
	}
	if(!is_post_id(id)){
		print "post-id: malformed id" > "/fd/2"
		exit 1
	}
	print id
}
