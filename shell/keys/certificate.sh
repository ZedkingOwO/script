#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-02-07
#FileName:          certificate.sh
#Copyright (C):     2020 All rights reserved
#********************************************************************

SITE_NAME=www.lxj.org
CA_SUBJECT="/O=wang/CN=ca.magedu.org"
SUBJECT="/C=CN/ST=henan/L=zhengzhou/O=lxj/CN=$SITE_NAME"
SERIAL=34
EXPIRE=202002
FILE=$SITE_NAME

openssl req  -x509 -newkey rsa:2048 -subj $CA_SUBJECT -keyout ca.key -nodes -days 202002 -out ca.crt

openssl req -newkey rsa:2048 -nodes -keyout ${FILE}.key  -subj $SUBJECT -out ${FILE}.csr

openssl x509 -req -in ${FILE}.csr  -CA ca.crt -CAkey ca.key -set_serial $SERIAL  -days $EXPIRE -out ${FILE}.crt

chmod 600 ${FILE}.key ca.key
