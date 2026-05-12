#!/bin/awk -f /bin/9social/lib/id/common.awk -f
BEGIN {
	if(ARGC != 2){
		print "usage: 9social/lib/id/encode.awk <post-id>" > "/fd/2"
		exit 1
	}
	id = ARGV[1]
	if(!is_post_id(id)){
		print "encode.awk: malformed post id" > "/fd/2"
		exit 1
	}
	gsub(/:/, "_", id)
	print id
}
