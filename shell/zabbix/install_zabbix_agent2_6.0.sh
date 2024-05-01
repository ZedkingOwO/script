#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2022-03-06
#FileName:          install_zabbix_agent2_6.0.sh
#Description:       The test script
#Copyright (C):     2022 All rights reserved
#********************************************************************

ZABBIX_SERVER=zabbix.wang.org
ZABBIX_MAJOR_VER=6.0
ZABBIX_VER=${ZABBIX_MAJOR_VER}-4

URL="mirror.tuna.tsinghua.edu.cn/zabbix"
ZABBIX_HOSTNAME=web-`hostname -I`
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

install_zabbix_agent2() {
    if [ $ID = "centos" -o $ID = "rocky" ];then
	     VERSION_ID=`echo $VERSION_ID|awk -F. '{print $1}'` 
         rpm -Uvh https://$URL/zabbix/${ZABBIX_MAJOR_VER}/rhel/${VERSION_ID}/x86_64/zabbix-release-${ZABBIX_VER}.el${VERSION_ID}.noarch.rpm
        if [ $? -eq 0 ];then
            color "YUM仓库准备完成" 0
        else
            color "YUM仓库配置失败,退出" 1
            exit
        fi
        sed -i "s#repo.zabbix.com#${URL}#" /etc/yum.repos.d/zabbix.repo
        yum -y install zabbix-agent2
    else 
        wget https://$URL/zabbix/${ZABBIX_MAJOR_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZABBIX_VER}+ubuntu${VERSION_ID}_all.deb
        if [ $? -eq 0 ];then
            color "APT仓库准备完成" 0
        else
            color "APT仓库配置失败,退出" 1
            exit
        fi
        dpkg -i zabbix-release_${ZABBIX_VER}+ubuntu${VERSION_ID}_all.deb
        sed -i "s#repo.zabbix.com#${URL}#"   /etc/apt/sources.list.d/zabbix.list
        apt update
        apt -y install zabbix-agent2
    fi
}

config_zabbix_agent2 (){ 
    sed -i  "/^Server=127.0.0.1/c Server=$ZABBIX_SERVER"  /etc/zabbix/zabbix_agent2.conf
    #sed -i -e "/^Server=127.0.0.1/c Server=$ZABBIX_SERVER"  -e "/^Hostname=Zabbix server/c Hostname=${ZABBIX_HOSTNAME}"  /etc/zabbix/zabbix_agent2.conf
}

start_zabbix_agent2 () {
    systemctl enable zabbix-agent2.service
    systemctl restart zabbix-agent2.service
    systemctl is-active zabbix-agent2.service
    if [ $?  -eq 0 ];then  
        echo "-------------------------------------------------------------------"
        color "Zabbix Agent 安装完成!" 0
    else
        color "Zabbix Agent 安装失败" 1
        exit
    fi
}

install_zabbix_agent2

config_zabbix_agent2

start_zabbix_agent2
