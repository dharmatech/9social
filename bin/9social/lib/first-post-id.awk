#!/bin/awk -f /bin/9social/lib/id.awk -f
# Print the first canonical 9social post ID found in the input fields.

{
	for(i=1; i<=NF; i++){
		if(is_post_id($i)){
			print $i
			exit
		}
	}
	exit 1
}
