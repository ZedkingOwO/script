#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-03-02
#FileName:          install_sonar_scanner.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#支持在线和离线安装

SONARQUBE_SERVER=10.0.0.210

SONAR_SCANNER_VER=5.0.1.3006
#SONAR_SCANNER_VER=4.8.0.2856
#SONAR_SCANNER_VER=4.7.0.2747
#SONAR_SCANNER_VER=4.6.2.2472
#SONAR_SCANNER_VER=4.3.0.2102

URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VER}-linux.zip"
GREEN="echo -e \E[32;1m"
END="\E[0m"
WORK_DIR=`pwd`

color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $"  OK  "    
    elif [ $2 = "failure" -o $2 = "1"  ] ;then 
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo 
}

install_sonar_scanner (){
    cd $WORK_DIR
    if [ ! -f sonar-scanner-cli-${SONAR_SCANNER_VER}-linux.zip ] ;then
        wget $URL || { color  "下载失败!" 1 ;exit ; }
    fi
    unzip sonar-scanner-cli-${SONAR_SCANNER_VER}-linux.zip -d /usr/local/src
    ln -s /usr/local/src/sonar-scanner-${SONAR_SCANNER_VER}-linux/ /usr/local/sonar-scanner
    ln -s /usr/local/sonar-scanner/bin/sonar-scanner /usr/local/bin/
    cat >>  /usr/local/sonar-scanner/conf/sonar-scanner.properties <<EOF
sonar.host.url=http://${SONARQUBE_SERVER}:9000 
sonar.sourceEncoding=UTF-8
EOF
    sonar-scanner -v
    if [ $?  -eq 0 ];then  
        echo 
        color "sonar_scanner 安装完成!" 0
    else
        color "sonar_scanner 安装失败!" 1
        exit
    fi 
}

install_sonar_scanner
