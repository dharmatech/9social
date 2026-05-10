#!/bin/awk -f

# Convert one feed profile and one post into one tab-separated timeline record.
# Like posts exit successfully without emitting a record.

function trim(s){
	gsub(/^[ \t]+/, "", s)
	gsub(/[ \t]+$/, "", s)
	return s
}

FILENAME==ARGV[1] {
	colon=index($0, ":")
	if(colon==0)
		next
	key=substr($0, 1, colon-1)
	val=trim(substr($0, colon+1))
	if(key=="name" && short=="")
		short=val
	else if(key=="display" && display=="")
		display=val
	next
}

{
	gsub(/\t/, "    ")
	if(!inbody){
		if($0==""){
			inbody=1
			next
		}
		colon=index($0, ":")
		if(colon==0){
			bad=1
			next
		}
		key=substr($0, 1, colon-1)
		val=trim(substr($0, colon+1))
		if(key=="date")
			date=val
		else if(key=="title")
			title=val
		else if(key=="type")
			type=val
		next
	}
	body[++nbody]=$0
}

END {
	if(short=="" || display=="")
		exit 1
	if(!inbody || bad || date=="")
		exit 1
	if(date !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/)
		exit 1
	if(type=="like")
		exit 0
	start=1
	while(start<=nbody && body[start] ~ /^[ \t]*$/)
		start++
	finish=nbody
	while(finish>=start && body[finish] ~ /^[ \t]*$/)
		finish--
	title=trim(title)
	if(title==""){
		for(i=start; i<=finish; i++){
			line=trim(body[i])
			if(line!=""){
				title=line
				break
			}
		}
	}
	preview1=""
	preview2=""
	total=0
	lines=0
	for(i=start; i<=finish && lines<2; i++){
		line=trim(body[i])
		if(line=="")
			continue
		avail=160-total
		if(avail<=0)
			break
		if(length(line)>avail){
			if(avail>3)
				line=substr(line, 1, avail-3) "..."
			else
				line=substr(line, 1, avail)
		}
		lines++
		if(lines==1)
			preview1=line
		else
			preview2=line
		total+=length(line)
		if(total<160)
			total++
		if(length(line)>=avail)
			break
	}
	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", date, short, ARGV[2], display, title, preview1, preview2, FILENAME
}
