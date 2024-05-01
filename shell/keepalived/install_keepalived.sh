#!/bin/bash
#
#******************************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:          2020-01-20
#FileName:      install_keepalived.sh
#Description:   install_keepalived 
#Copyright (C): 2020 All rights reserved
#******************************************************************************

#本脚本支持在线或离线编译安装

KEEPALIVED_VERSION=2.2.8
#KEEPALIVED_VERSION=2.2.7
#KEEPALIVED_VERSION=2.2.2
#KEEPALIVED_VERSION=2.0.20
KEEPALIVED_FILE=keepalived-${KEEPALIVED_VERSION}.tar.gz

KEEPALIVED_INSTALL_DIR=/usr/local/keepalived
SRC_DIR=/usr/local/src
KEEPALIVED_URL=https://keepalived.org/software/

CPUS=`grep -c processor  /proc/cpuinfo`

. /etc/os-release


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


download_file (){
    if [ $ID = 'centos' -o $ID = 'rocky' ];then
        rpm -q wget &> /dev/null || yum -y install wget 
    elif [ $ID = 'ubuntu' ];then
        dpkg -l |grep wget || { apt update;  apt install -y wget; } 
    else
        color "不支持此操作系统，退出!" 1
        exit
    fi
    if [ ! -e ${KEEPALIVED_FILE} ];then
        wget --no-check-certificate  ${KEEPALIVED_URL}${KEEPALIVED_FILE} 
        [ $? -ne 0 ] && { color "KEEPALIVED源码包下载失败" 1 ; exit; }
    fi
}

install_keepalived () {
    if [ $ID = 'centos' -o $ID = 'rocky' ];then
        yum -y install make gcc ipvsadm autoconf automake openssl-devel libnl3-devel iptables-devel net-snmp-devel glib2-devel pcre2-devel  libmnl-devel systemd-devel &> /dev/null
    elif [ $ID = 'ubuntu' ];then
        apt update 
        apt -y install make gcc ipvsadm build-essential pkg-config automake autoconf libipset-dev libnl-3-dev libnl-genl-3-dev libssl-dev libxtables-dev libip4tc-dev libip6tc-dev libipset-dev libmagic-dev libsnmp-dev libglib2.0-dev libpcre2-dev libnftnl-dev libmnl-dev libsystemd-dev
    else
        color "不支持此操作系统，退出!" 1
    fi
    tar xf ${KEEPALIVED_FILE} -C ${SRC_DIR}
    cd ${SRC_DIR}/keepalived-${KEEPALIVED_VERSION}
    #./configure --prefix=${KEEPALIVED_INSTALL_DIR} --disable-fwmark
    ./configure --prefix=${KEEPALIVED_INSTALL_DIR} 
    make -j $CPUS && make install
    if [ $? -eq 0 ];then
        color "KEEPALIVED编译安装成功" 0
    else
        color "KEEPALIVED编译安装失败,退出!" 1
        exit
    fi
    [ -d /etc/keepalived ] || mkdir -p /etc/keepalived
    cp ${KEEPALIVED_INSTALL_DIR}/etc/keepalived/keepalived.conf.sample  /etc/keepalived/keepalived.conf
}

start_keepalived () {
    cp ./keepalived/keepalived.service /lib/systemd/system/
    systemctl daemon-reload
    systemctl enable --now keepalived &> /dev/null 
    systemctl is-active keepalived
    if [ $? -eq 0 ] ;then
        color "Keepalived 服务安装成功!" 0  
    else
        color "Keepalived 服务安装失败!" 1
        exit 1
    fi
}

download_file

install_keepalived

start_keepalived
