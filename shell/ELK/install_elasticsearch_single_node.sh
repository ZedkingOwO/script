#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-06-03
#FileName:          install_elasticsearch_single_node.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#只支持在线下载

ES_VERSION=8.9.0
#ES_VERSION=8.8.2
#ES_VERSION=8.6.1
#ES_VERSION=7.17.5
#ES_VERSION=7.9.3
#ES_VERSION=7.6.2
ES_MAGJOR_VERSION=`echo $ES_VERSION|cut -d. -f1`
UBUNTU_URL="https://mirrors.tuna.tsinghua.edu.cn/elasticstack/${ES_MAGJOR_VERSION}.x/apt/pool/main/e/elasticsearch/elasticsearch-${ES_VERSION}-amd64.deb"
RHEL_URL="https://mirrors.tuna.tsinghua.edu.cn/elasticstack/${ES_MAGJOR_VERSION}.x/yum/${ES_VERSION}/elasticsearch-${ES_VERSION}-x86_64.rpm"

LOCAL_IP=`hostname -I|awk '{print $1}'`

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

check_mem () {
    MEM_TOTAL=`head -n1 /proc/meminfo |awk '{print $2}'`
    if [ ${MEM_TOTAL} -lt 1997072 ];then
        color '内存低于2G,安装失败!' 1
        exit
    elif [ ${MEM_TOTAL} -le 2997072 ];then
        color '内存不足3G,建议调整内存大小!' 2
    else
        return
    fi
}

install_es() {
    if [ $ID = "centos" -o $ID = "rocky" ];then
        if [ ! -f elasticsearch-${ES_VERSION}-x86_64.rpm ];then
             wget -P /usr/local/src/ $RHEL_URL || { color  "下载失败!" 1 ;exit ; } 
        fi
        yum -y install ${RHEL_URL##*/}
    elif [ $ID = "ubuntu" ];then
        if [ ! -f elasticsearch-${ES_VERSION}-amd64.deb ];then
           wget $UBUNTU_URL || { color  "下载失败!" 1 ;exit ; }
        fi
        dpkg -i ${UBUNTU_URL##*/}
    else
        color "不支持此操作系统!" 1
        exit
    fi
    [ $? -eq 0 ] ||  { color '安装软件包失败,退出!' 1; exit; }
}

config_es () {
    cp /etc/elasticsearch/elasticsearch.yml{,.bak}
    cat > /etc/elasticsearch/elasticsearch.yml  <<EOF
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
http.host: 0.0.0.0

#8.X 的配置
xpack.security.enabled: false
xpack.security.enrollment.enabled: true

xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12

EOF

    mkdir -p /etc/systemd/system/elasticsearch.service.d/
    cat > /etc/systemd/system/elasticsearch.service.d/override.conf <<EOF
[Service]
LimitMEMLOCK=infinity
EOF
    systemctl daemon-reload
    systemctl enable  elasticsearch.service
}

prepare_es() {
    echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
    sysctl  -p
}

start_es(){
    systemctl start elasticsearch || { color "启动失败!" 1;exit 1; }
    sleep 3
    curl http://127.0.0.1:9200 && color "安装成功" 0   || { color "安装失败!" 1; exit 1; } 
    echo -e "请访问链接: \E[32;1mhttp://`hostname -I|awk '{print $1}'`:9200/\E[0m"
}


check_mem

install_es

config_es

prepare_es

start_es

