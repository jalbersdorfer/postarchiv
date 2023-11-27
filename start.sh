#!/bin/bash
./importFiles.sh &
./cleanup.sh &
perl ./dancerApp.pl
