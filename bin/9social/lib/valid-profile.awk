#!/bin/awk -f
# Validate a 9social profile file.
#
# Requires:
#   id: 9social:user:<uuid>
#   name: <non-empty name>
#   display: <non-empty display name>
#
# On success, prints:
#   <uuid without 9social:user: prefix>
#   <name>
#
# On failure, exits nonzero and prints nothing.

# Remove leading and trailing spaces and tabs.
function trim(s)
{
	gsub(/^[ \t]+/, "", s)
	gsub(/[ \t]+$/, "", s)
	return s
}

BEGIN {
	if(ARGC != 2)
		exit 1
}

index($0, ": ") == 0 { bad = 1; next }

{
	key = substr($0, 1, index($0, ": ") - 1)
	value = trim(substr($0, index($0, ": ") + 2))
	if(key == "id")
		id = value
	else if(key == "name")
		name = value
	else if(key == "display")
		display = value
}

END {
	if(bad || id == "" || name == "" || display == "")
		exit 1
	if(id !~ /^9social:user:[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/)
		exit 1
	uuid = id
	sub(/^9social:user:/, "", uuid)
	print uuid
	print name
}
