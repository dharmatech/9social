#!/bin/awk -f
# Render sorted tab-separated timeline records for display.

BEGIN {
	FS = "\t"
	sep = "------------------------------------------------------------------------"
}

{
	print sep
	print $1 "  " $4
	print $8
	print "title: " $5
	if($6 != "")
		print $6
	if($7 != "")
		print $7
	print ""
}
