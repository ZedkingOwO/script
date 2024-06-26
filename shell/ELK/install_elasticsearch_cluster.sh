#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-06-03
#FileName:          install_elasticsearch_cluster.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#只支持在线下载

ES_VERSION=8.0.0
#ES_VERSION=8.8.2
#ES_VERSION=7.17.5
#ES_VERSION=7.9.3
#ES_VERSION=7.6.2
UBUNTU_URL="https://mirrors.tuna.tsinghua.edu.cn/elasticstack/7.x/apt/pool/main/e/elasticsearch/elasticsearch-${ES_VERSION}-amd64.deb"
RHEL_URL="https://mirrors.tuna.tsinghua.edu.cn/elasticstack/7.x/yum/${ES_VERSION}/elasticsearch-${ES_VERSION}-x86_64.rpm"

CLUSTER_NAME=es-cluster
NODE_LIST='["10.0.0.101","10.0.0.102","10.0.0.103"]'
ES_DATA=/data/es-data
ES_LOGS=/data/es-logs

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

set_node_id () {
    read -p "请输入node编号(默认为 1): " NODE_ID

    if [ -z "$NODE_ID" ] ;then
        NODE_ID=1
    elif [[ ! "$NODE_ID" =~ ^[0-9]+$ ]];then
        color  "请输入正确的node编号!" 1
        exit
    else
        true
    fi
    NODE_NAME=node-$NODE_ID
}

install_es() {
    if [ $ID = "centos" -o $ID = "rocky" ];then
        wget -P /usr/local/src/ $RHEL_URL || { color  "下载失败!" 1 ;exit ; } 
        yum -y install /usr/local/src/${RHEL_URL##*/}
    elif [ $ID = "ubuntu" ];then
        wget -P /usr/local/src/ $UBUNTU_URL || { color  "下载失败!" 1 ;exit ; }
        dpkg -i /usr/local/src/${UBUNTU_URL##*/}
    else
        color "不支持此操作系统!" 1
        exit
    fi
    [ $? -eq 0 ] ||  { color '安装软件包失败,退出!' 1; exit; }
}

config_es () {
    cp /etc/elasticsearch/elasticsearch.yml{,.bak}
    cat > /etc/elasticsearch/elasticsearch.yml  <<EOF
cluster.name: $CLUSTER_NAME
node.name: $NODE_NAME
path.data: $ES_DATA
path.logs: $ES_LOGS
bootstrap.memory_lock: true
network.host: 0.0.0.0
discovery.seed_hosts: $NODE_LIST
cluster.initial_master_nodes: $NODE_LIST
gateway.recover_after_nodes: 2
action.destructive_requires_name: true
xpack.security.enabled: false #8.X 特有
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
    mkdir -p $ES_DATA $ES_LOGS
    chown  -R elasticsearch.elasticsearch $ES_DATA $ES_LOGS
}

start_es(){
    systemctl start elasticsearch || { color "启动失败!" 1;exit 1; }
    sleep 3
    curl http://127.0.0.1:9200 && color "安装成功" 0   || { color "安装失败!" 1; exit 1; } 
    echo -e "请访问链接: \E[32;1mhttp://`hostname -I|awk '{print $1}'`:9200/\E[0m"
}

check_mem
set_node_id
install_es
config_es
prepare_es
start_es

