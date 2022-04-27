#!/bin/bash

while true
do
	find /app/import/* -exec ./importFile.sh {} reindex \;
	echo imported all Files
	sleep 3
done

