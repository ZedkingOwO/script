#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-06-03
#FileName:          install_zookeeper_cluster.sh  
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#支持在线和离线安装

ZK_VERSION=3.9.1
#ZK_VERSION=3.9.0
#ZK_VERSION=3.8.1
#ZK_VERSION=3.8.0
#ZK_VERSION=3.6.3
#ZK_VERSION=3.7.1

#3.5.0及以上版本下载链接
ZK_URL=https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-${ZK_VERSION}/apache-zookeeper-${ZK_VERSION}-bin.tar.gz
#ZK_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/stable/apache-zookeeper-${ZK_VERSION}-bin.tar.gz"
#ZK_URL=https://archive.apache.org/dist/zookeeper/zookeeper-${ZK_VERSION}/apache-zookeeper-${ZK_VERSION}-bin.tar.gz
#ZK_URL=https://archive.apache.org/dist/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.bin.tar.gz

#3.5.0以下版本下载链接
#ZK_VERSION=3.4.14
#ZK_URL=https://archive.apache.org/dist/zookeeper/zookeeper-${ZK_VERSION}/zookeeper-${ZK_VERSION}.tar.gz


NODE1=10.0.0.204
NODE2=10.0.0.205
NODE3=10.0.0.206

ZK_INSTALL_DIR=/usr/local/zookeeper

.  /etc/os-release

HOST=`hostname -I|awk '{print $1}'`

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

env () {
    if hostname -I |grep -q $NODE1;then
	    ID=1
		hostnamectl set-hostname node1
	elif hostname -I |grep -q $NODE2;then
	    ID=2
		hostnamectl set-hostname node2
	elif hostname -I |grep -q $NODE3;then
	    ID=3
		hostnamectl set-hostname node3
    else
	    color 'IP地址错误' 1
		exit
	fi
    cat >> /etc/hosts <<EOF
	
$NODE1   node1
$NODE2   node2
$NODE3   node3

EOF
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


install_zookeeper() {
    if [ ! -f apache-zookeeper-${ZK_VERSION}-bin.tar.gz ] ;then
        wget  --no-check-certificate $ZK_URL || { color  "下载失败!" 1 ;exit ; }
    fi
    [ -e `dirname ${ZK_INSTALL_DIR}` ] || mkdir -pv `dirname ${ZK_INSTALL_DIR}`
    tar xf apache-zookeeper-${ZK_VERSION}-bin.tar.gz -C `dirname ${ZK_INSTALL_DIR}`
    ln -s /usr/local/apache-zookeeper-${ZK_VERSION}-bin/ ${ZK_INSTALL_DIR}
    echo "PATH=${ZK_INSTALL_DIR}/bin:$PATH" >>  /etc/profile
	mkdir -p ${ZK_INSTALL_DIR}/data	
    echo $ID > ${ZK_INSTALL_DIR}/data/myid
    cat > ${ZK_INSTALL_DIR}/conf/zoo.cfg <<EOF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=${ZK_INSTALL_DIR}/data
clientPort=2181
maxClientCnxns=128
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
server.1=${NODE1}:2888:3888
server.2=${NODE2}:2888:3888
server.3=${NODE3}:2888:3888
EOF
	cat > /lib/systemd/system/zookeeper.service <<EOF
[Unit]
Description=zookeeper.service
After=network.target

[Service]
Type=forking
ExecStart=${ZK_INSTALL_DIR}/bin/zkServer.sh start
ExecStop=${ZK_INSTALL_DIR}/bin/zkServer.sh stop
ExecReload=${ZK_INSTALL_DIR}/bin/zkServer.sh restart

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now  zookeeper.service
    systemctl is-active zookeeper.service
	if [ $? -eq 0 ] ;then 
        color "zookeeper 安装成功!" 0  
    else 
        color "zookeeper 安装失败!" 1
        exit 1
    fi   
}

env

install_jdk

install_zookeeper
