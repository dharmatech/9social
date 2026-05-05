#!/bin/awk -f
# Validate a 9social profile and print uuid and name.

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
