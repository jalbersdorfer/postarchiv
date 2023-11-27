#!/bin/bash

while true
do
  hour=$(/bin/date +%H)
  echo $ELDOAR_REMOVE_DELETED_AFTER_DAYS
  if [[ "$hour" == "3" && "$ELDOAR_REMOVE_DELETED_AFTER_DAYS" > 0 ]]
  then
    echo $(date): start cleanup
    find /app/data/files/ -type f -mtime +$ELDOAR_REMOVE_DELETED_AFTER_DAYS -name "*.deleted" -ls -delete
    echo $(date): cleanup done
  fi
	sleep 3600
done

