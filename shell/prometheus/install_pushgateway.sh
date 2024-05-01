#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-02-07
#FileName:          install_pushgateway.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#支持在线和离线安装，建议离线

PUSHGATEWAY_VERSION=1.7.0
#PUSHGATEWAY_VERSION=1.5.1
#PUSHGATEWAY_VERSION=1.4.3
PUSHGATEWAY_FILE="pushgateway-${PUSHGATEWAY_VERSION}.linux-amd64.tar.gz"
PUSHGATEWAY_URL=https://github.com/prometheus/pushgateway/releases/download/v${PUSHGATEWAY_VERSION}/${PUSHGATEWAY_FILE}
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


install_pushgateway () {
    if [ ! -f  ${PUSHGATEWAY_FILE} ] ;then
        wget ${PUSHGATEWAY_URL} ||  { color "下载失败!" 1 ; exit ; }
    fi
    [ -d $INSTALL_DIR ] || mkdir -p $INSTALL_DIR
    tar xf ${PUSHGATEWAY_FILE} -C $INSTALL_DIR
    cd $INSTALL_DIR &&  ln -s pushgateway-${PUSHGATEWAY_VERSION}.linux-amd64 pushgateway
    mkdir -p $INSTALL_DIR/pushgateway/bin
    cd $INSTALL_DIR/pushgateway &&  mv pushgateway bin/ 
	id prometheus &>/dev/null || useradd -r -g prometheus -s /sbin/nologin prometheus
	chown -R prometheus.prometheus $INSTALL_DIR/pushgateway/
    ln -s $INSTALL_DIR/pushgateway/bin/pushgateway /usr/local/bin/
}


pushgateway_service () {
    cat > /lib/systemd/system/pushgateway.service <<EOF
[Unit]
Description=Prometheus Pushgateway
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/pushgateway/bin/pushgateway
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
User=prometheus
Group=prometheus


[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now pushgateway.service
}


start_pushgateway() { 
    systemctl is-active pushgateway.service
    if [ $?  -eq 0 ];then  
        echo 
        color "pushgateway 安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        msg_info "http://$HOST:9091" 
    else
        color "pushgateway 安装失败!" 1
        exit
    fi 
}

install_pushgateway

pushgateway_service

start_pushgateway
