#!/bin/bash
#
#----------------------------------------------------------------
#Author:			          joker
#QQ:          	 	          505697096
#Date:                        2023-12-05
#Filename:                    backup.sh
#
#----------------------------------------------------------------
#

UNAME=zed
PWD=123456
IP=10.0.0.161
IGNORE='Database|information_schema|performance_schema|sys'
YMD=`date +%F`

if [ ! -d /root/backup/${YMD} ];then
    mkdir -pv /root/backup/${YMD}
fi

DBLIST=`mysql -u${UNAME} -p${PWD} -h$IP -e "show databases;" 2>/dev/null | grep -Ewv "$IGNORE"`

for db in ${DBLIST};do
    mysqldump -u${UNAME} -p${PWD} -B $db -h$IP 2>/dev/null 1>/root/backup/${db}_${YMD}.sql
    if [ $? -eq 0 ];then
        echo -e "${db}_${YMD} [1;5;32m  backup [OK][0m"
    else
        echo -e "${db}_${YMD} [1;31m  backup [NO][0m"
       
    fi
done

