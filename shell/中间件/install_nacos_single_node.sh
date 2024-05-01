#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2023-06-05
#FileName:          install_nacos_single_node.sh
#Description:       The test script
#Copyright (C):     2023 All rights reserved
#********************************************************************

#支持在线和离线安装,建议离线安装,在线可能下载很慢

NACOS_VERSION=2.3.0
#NACOS_VERSION=2.2.3
NACOS_FILE=nacos-server-${NACOS_VERSION}.tar.gz
NACOS_URL=https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}/${NACOS_FILE}

INSTALL_DIR=/usr/local/nacos


HOST=`hostname -I|awk '{print $1}'`

.  /etc/os-release

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


install_jdk() {
    java -version &>/dev/null && { color "JDK 已安装!" 1 ; return;  }
    if command -v yum &>/dev/null ; then
        yum -y install java-1.8.0-openjdk-devel || { color "安装JDK失败!" 1; exit 1; }
    elif command -v apt &>/dev/null ; then
        apt update
        #apt install openjdk-11-jdk -y || { color "安装JDK失败!" 1; exit 1; } 
        apt install openjdk-8-jdk -y || { color "安装JDK失败!" 1; exit 1; } 
    else
       color "不支持当前操作系统!" 1
       exit 1
    fi
    java -version && { color "安装 JDK 完成!" 0 ; } || { color "安装JDK失败!" 1; exit 1; } 
}


install_nacos() {
    if [ -f ${NACOS_FILE} ] ;then
        cp ${NACOS_FILE} /usr/local/src/
    else
        wget -P /usr/local/src/ --no-check-certificate $NACOS_URL || { color  "下载失败!" 1 ;exit ; }
    fi
    tar xf /usr/local/src/${NACOS_FILE} -C /usr/local
    
    echo "PATH=${INSTALL_DIR}/bin:$PATH" >>  /etc/profile
    .  /etc/profile
   
start_nacos () {   
    cat > /lib/systemd/system/nacos.service <<EOF
[Unit]
Description=nacos.service
After=network.target

[Service]
Type=forking
#Environment=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/bin/startup.sh -m standalone
ExecStop=${INSTALL_DIR}/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now  nacos.service
    systemctl is-active nacos.service
    if [ $? -eq 0 ] ;then 
        color "nacos 安装成功!" 0  
        echo "-------------------------------------------------------------------"
        echo -e "请访问链接: \E[32;1mhttp://$HOST:8848/nacos/\E[0m" 
    else 
        color "nacos 安装失败!" 1
        exit 1
    fi   
}
}



install_jdk

install_nacos

start_nacos
