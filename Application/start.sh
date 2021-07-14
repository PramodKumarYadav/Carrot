#!/bin/sh

./wait-for-it.sh rabbit:5672
echo 'rabbit is up - sleeping 10 seconds'
sleep 10 
./main 42 #autosend = 42
