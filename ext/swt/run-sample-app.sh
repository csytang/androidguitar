#!/bin/sh

if [ "$1" == '' ]; then
	echo "USAGE: $0 <APP_NAME>"
else
	cd ./$1
	ant $1
fi
