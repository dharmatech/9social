#!/bin/awk -f
# Convert the first line of a file into a post filename slug.
#
# Prints a lowercase, dash-separated slug no longer than 48 characters.
# If the line has no usable alphanumeric characters, prints `post`.

function slugify(s)
{
	s = tolower(s)
	gsub(/[ 	]+/, "-", s)
	gsub(/[^a-z0-9-]/, "", s)
	gsub(/-+/, "-", s)
	gsub(/^-+/, "", s)
	gsub(/-+$/, "", s)
	s = substr(s, 1, 48)
	gsub(/-+$/, "", s)
	if(s == "")
		s = "post"
	return s
}

BEGIN {
	if(ARGC != 2){
		failed = 1
		exit 1
	}
}

NR == 1 {
	print slugify($0)
	done = 1
	exit
}

END {
	if(failed)
		exit 1
	if(!done)
		print "post"
}
