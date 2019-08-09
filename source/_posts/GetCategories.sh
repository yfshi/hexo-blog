#!/bin/bash

Usage()
{
	echo "Usage:"
	echo "  -l      list all categories."
	echo "  -a      list all categories and files."
}

ListAll()
{
	for cat in `cat *.md | grep categories | sort | uniq | awk '{print $2}'`
	do
		echo "[$cat]:"
		grep 'categories:' *.md | grep "$cat" | awk -F: '{print "    "$1}'
	done
}

List()
{
	cat *.md | grep '^categories' | sort | uniq | awk '{print $2}'
}

case $1 in
'-a'|'-A'|'all')
	ListAll;;
'-l'|'-L'|'list')
	List;;
*)
	Usage
esac

