#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Description:		The test script
#Copyright (C): 	2020 All rights reserved
#********************************************************************

ZABBIX_SERVER=zabbix.lxj.org
TOKEN=$(./zabbix-api-token.sh| awk -F'"' '{print $8}')

curl -s -XPOST -H "Content-Type: application/json-rpc" -d '
{
"jsonrpc": "2.0",
"method": "host.get",
"params": {
    "filter": {
         "host": [ "10.0.0.8" ]
     }
},
"id": 1,
"auth": "'$TOKEN'"
}' http://${ZABBIX_SERVER}/zabbix/api_jsonrpc.php | python3 -m json.tool
