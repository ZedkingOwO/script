#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date: 			2020-09-08
#Description:		The test script
#Copyright (C): 	2020 All rights reserved
#********************************************************************

ZABBIX_SERVER=zabbix.lxj.org
TOKEN=$(./zabbix-api-token.sh| awk -F'"' '{print $8}')

for i in {200..250};do
HOST=10.0.0.$i

curl -s -XPOST -H "Content-Type: application/json-rpc" -d '
{
"jsonrpc": "2.0",
"method": "host.create",
"params": {
    "host": "'web-api-$HOST'",
    "name": "'web-api-$HOST'",
    "interfaces": [
        {
        "type": 1,
        "main": 1,
        "useip": 1,
        "ip": "'$HOST'",
        "dns": "",
        "port": "10050"
        }
    ],
    "groups": [ 
        {
            "groupid": "2" 
        }
    ],
    "templates": [ 
        {
            "templateid": "10001" 
        } 
    ]
 },
"id": 1,
"auth": "'$TOKEN'"
}' http://${ZABBIX_SERVER}/zabbix/api_jsonrpc.php | python3 -m json.tool
done


