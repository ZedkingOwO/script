#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date: 			2020-09-08
#FileName:		zabbix-api-token.sh
#Description:		The test script
#Copyright (C): 	2020 All rights reserved
#********************************************************************

ZABBIX_SERVER=zabbix.lxj.org

curl -s -XPOST -H "Content-Type: application/json-rpc" -d '                                           
{
"jsonrpc": "2.0",
"method": "user.login",
"params": {
"user": "Admin",
"password": "zabbix"
},
"id": 1,
"auth": null
}' http://${ZABBIX_SERVER}/zabbix/api_jsonrpc.php 
