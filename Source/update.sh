#!/bin/sh
cd "`dirname "$0"`"
echo `which uno`

for f in "`pwd -P`"/*; do
	if [ -d $f ]; then
		echo "Updating '$f'"
		uno update --strip $f
	fi
done
