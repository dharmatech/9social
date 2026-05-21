#!/bin/awk -f /bin/9social/lib/id/common.awk -f
# Emit tab-separated thread records for posts listed in an index/posts directory.

BEGIN {
	indexposts = ARGV[1]
	ARGV[1] = ""
	ARGC = 1
}

function clean_field(s)
{
	gsub(/\t/, "    ", s)
	return s
}

function reset_post()
{
	data["id"] = ""
	data["date"] = ""
	data["author"] = ""
	data["title"] = ""
	data["type"] = ""
	data["target"] = ""
}

function read_post(path,    line, key, value)
{
	reset_post()
	while((getline line < path) > 0){
		if(line ~ /^[ \t]*$/)
			break
		if(line !~ /^[A-Za-z][A-Za-z0-9-]*:[ \t]*/){
			close(path)
			return 1
		}
		key = line
		sub(/:.*/, "", key)
		value = line
		sub(/^[A-Za-z][A-Za-z0-9-]*:[ \t]*/, "", value)
		sub(/[ \t]*$/, "", value)
		data[key] = value
	}
	close(path)
	return 0
}

function emit_record(postpath,    target)
{
	if(! is_post_id(data["id"]))
		return
	target = ""
	if((data["type"] == "reply" || data["type"] == "like") && is_post_id(data["target"]))
		target = data["target"]
	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
		data["id"],
		data["date"],
		clean_field(data["author"]),
		clean_field(data["title"]),
		data["type"],
		target,
		postpath
}

{
	indexfile = indexposts "/" $0
	if((getline postpath < indexfile) <= 0){
		close(indexfile)
		next
	}
	close(indexfile)
	if(read_post(postpath))
		exit 1
	emit_record(postpath)
}
