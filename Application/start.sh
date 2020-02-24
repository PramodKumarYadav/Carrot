#!/bin/sh

./wait-for-it.sh rabbit:5672
echo 'rabbit is up - sleeping 10 seconds'
sleep 10 
./main 9001 #autosend = 9001
