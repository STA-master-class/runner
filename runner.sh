#!/bin/bash

while true
do
	for i in {1..10}
	do
		touch ${i}.txt
	done
	for i in {1..10}
	do
		mv ${i}.txt ${i}.txt.1
	done
	
	sleep 7200
done