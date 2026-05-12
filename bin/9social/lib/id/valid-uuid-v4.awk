#!/bin/awk -f /bin/9social/lib/id/common.awk -f
# Exit successfully only if the input contains a canonical lowercase UUIDv4.

{
	if(is_uuid_v4($0))
		ok = 1
}

END {
	exit !ok
}
