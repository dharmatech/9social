#!/bin/awk -f
# Read text from stdin and print the first 9social post file path
# found as a whitespace-delimited field.
#
# Output:
#   the first matching local post file path
#
# Exits nonzero and prints nothing if no post path is found.

function is_post_path(s,    in_feeds, in_self, in_posts)
{
	in_feeds = index(s, "/lib/9social/feeds/")      > 0
	in_self  = index(s, "/lib/9social/self/posts/") > 0
	in_posts = index(s, "/posts/")                  > 0

	return (in_feeds && in_posts) || in_self
}

{
	for(i = 1; i <= NF; i++){
		if(is_post_path($i)){
			print $i
			exit
		}
	}
	exit 1
}
