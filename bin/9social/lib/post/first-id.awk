#!/bin/awk -f /bin/9social/lib/id/common.awk -f
# Read text from stdin and print the first canonical 9social post ID
# found as a whitespace-delimited field.
#
# Output:
#   the first matching 9social:post:<user-uuid>:<post-uuid>
#
# Exits nonzero and prints nothing if no post ID is found.

{
	for(i=1; i<=NF; i++){
		if(is_post_id($i)){
			print $i
			exit
		}
	}
	exit 1
}
