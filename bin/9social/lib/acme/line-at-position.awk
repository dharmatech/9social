#!/bin/awk -f
# Print the line containing a zero-based character position.
#
# Usage:
#   9social/lib/acme/line-at-position.awk <position> [file]

BEGIN {
	if(ARGC < 2 || ARGC > 3){
		print "usage: 9social/lib/acme/line-at-position.awk <position> [file]" > "/fd/2"
		exit 1
	}
	pos = ARGV[1]
	if(pos !~ /^[0-9]+$/){
		print "line-at-position.awk: bad position" > "/fd/2"
		exit 1
	}
	if(ARGC == 2)
		ARGC = 1
	else
		ARGV[1] = ""
	start = 0
}

{
	end = start + length($0)
	if(pos >= start && pos <= end){
		print
		found = 1
		exit
	}
	start = end + 1
}

END {
	if(!found)
		exit 1
}
