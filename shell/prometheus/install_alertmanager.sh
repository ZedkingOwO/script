#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-02-07
#FileName:          install_alertmanager.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#支持在线和离线安装，在线下载可能很慢,建议离线安装

ALERTMANAGER_VERSION=0.27.0
#ALERTMANAGER_VERSION=0.25.0
#ALERTMANAGER_VERSION=0.24.0
#ALERTMANAGER_VERSION=0.23.0

ALERTMANAGER_FILE="alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
ALERTMANAGE_URL="https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/${ALERTMANAGER_FILE}"
INSTALL_DIR=/usr/local

HOST=`hostname -I|awk '{print $1}'`
. /etc/os-release

msg_error() {
  echo -e "\033[1;31m$1\033[0m"
}

msg_info() {
  echo -e "\033[1;32m$1\033[0m"
}

msg_warn() {
  echo -e "\033[1;33m$1\033[0m"
}


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


install_alertmanager () {
    if [ ! -f  ${ALERTMANAGER_FILE} ] ;then
        wget ${ALERTMANAGE_URL}  || { color "下载失败!" 1 ; exit ; }
    fi
    [ -d $INSTALL_DIR ] || mkdir -p $INSTALL_DIR
    tar xf ${ALERTMANAGER_FILE} -C $INSTALL_DIR
    cd $INSTALL_DIR &&  ln -s alertmanager-${ALERTMANAGER_VERSION}.linux-amd64 alertmanager
    mkdir -p $INSTALL_DIR/alertmanager/{bin,conf,data}
    cd $INSTALL_DIR/alertmanager && { mv alertmanager.yml conf/;  mv alertmanager amtool bin/; }
	id prometheus &> /dev/null ||useradd -r -g prometheus -s /sbin/nologin prometheus
    chown -R prometheus.prometheus $INSTALL_DIR/alertmanager/
      
    cat >>  /etc/profile <<EOF
export ALERTMANAGER_HOME=${INSTALL_DIR}/alertmanager
export PATH=\${ALERTMANAGER_HOME}/bin:\$PATH
EOF

}


alertmanager_service () {
    cat > /lib/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Prometheus alertmanager
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/alertmanager/bin/alertmanager --config.file=${INSTALL_DIR}/alertmanager/conf/alertmanager.yml --storage.path=${INSTALL_DIR}/alertmanager/data --web.listen-address=0.0.0.0:9093
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
User=prometheus
Group=prometheus

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now alertmanager.service
}


start_alertmanager() { 
    systemctl is-active alertmanager.service
    if [ $?  -eq 0 ];then
        echo
        color "alertmanager 安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        msg_info "http://$HOST:9093"
    else
        color "alertmanager 安装失败!" 1
        exit
    fi

}

install_alertmanager

alertmanager_service

start_alertmanager
