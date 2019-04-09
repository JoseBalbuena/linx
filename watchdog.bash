#!/bin/bash

#Script to start NGINX
ps -ef | grep nginx |grep -v grep > /dev/null
if [ $? != 0 ]
then
       systemctl start nginx > /dev/null
fi

#Script to start linxapp.js APP
ps -ef | grep linxapp.js |grep -v grep > /dev/null
if [ $? != 0 ]
then
       pm2 start linxapp > /dev/null
fi
