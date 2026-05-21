#!/bin/awk -f
# Read normalized thread records and render the threaded view.

BEGIN { FS = "\t" }

function better(a, b, newest)
{
	if(date[a] != date[b]){
		if(newest)
			return date[a] > date[b]
		return date[a] < date[b]
	}
	return id[a] < id[b]
}

function sortlist(list, n, newest, gap, i, j, tmp)
{
	for(gap = int(n / 2); gap > 0; gap = int(gap / 2)){
		for(i = gap + 1; i <= n; i++){
			tmp = list[i]
			for(j = i; j > gap && !better(list[j - gap], tmp, newest); j = j - gap)
				list[j] = list[j - gap]
			list[j] = tmp
		}
	}
}

function countsuffix(node,    suffix)
{
	suffix = ""
	if(likecount[node] > 0)
		suffix = suffix " L:" likecount[node]
	if(childn[node] > 0)
		suffix = suffix " R:" childn[node]
	return suffix
}

function printentry(node, depth,    indent, i)
{
	indent = ""
	for(i = 0; i < depth; i++)
		indent = indent "    "
	print indent date[node] "  " author[node] countsuffix(node)
	print indent id[node]
	if(title[node] == "")
		print indent "title:"
	else
		print indent "title: " title[node]
}

function sortchildren(parent,    gap, i, j, tmp, n)
{
	n = childn[parent]
	for(gap = int(n / 2); gap > 0; gap = int(gap / 2)){
		for(i = gap + 1; i <= n; i++){
			tmp = child[parent, i]
			for(j = i; j > gap && !better(child[parent, j - gap], tmp, 0); j = j - gap)
				child[parent, j] = child[parent, j - gap]
			child[parent, j] = tmp
		}
	}
}

function render(node, depth,    i, nxt)
{
	if(active[node]){
		print "ShowThreads: cycle at " id[node] > "/fd/2"
		return
	}
	active[node] = 1
	rendered[node] = 1
	printentry(node, depth)
	sortchildren(node)
	for(i = 1; i <= childn[node]; i++){
		if(i > 1)
			print ""
		nxt = child[node, i]
		render(nxt, depth + 1)
	}
	active[node] = 0
}

{
	key = $1
	type = $5
	rectarget = $6
	if(type == "like"){
		if(rectarget != "" && $3 != "" && !likeseen[rectarget, $3]){
			likeseen[rectarget, $3] = 1
			likecount[rectarget]++
		}
		next
	}
	seen[key] = 1
	id[key] = $1
	date[key] = $2
	author[key] = $3
	title[key] = $4
	if(type == "reply")
		target[key] = rectarget
	all[++alln] = key
}

END {
	for(i = 1; i <= alln; i++){
		node = all[i]
		if(target[node] != "" && seen[target[node]])
			child[target[node], ++childn[target[node]]] = node
		else
			roots[++rootn] = node
	}

	sortlist(roots, rootn, 1)
	for(i = 1; i <= rootn; i++){
		if(i > 1)
			print ""
		render(roots[i], 0)
	}

	for(i = 1; i <= alln; i++){
		node = all[i]
		if(!rendered[node]){
			if(printed_extra)
				print ""
			if(rootn > 0 && !printed_extra)
				print ""
			printed_extra = 1
			print "ShowThreads: unattached cycle or malformed thread at " id[node] > "/fd/2"
			render(node, 0)
		}
	}
}
