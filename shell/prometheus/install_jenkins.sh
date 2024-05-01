#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-02-15
#FileName:          install_jenkins.sh
#Description:       本脚本只支持Jenkins-2.319.3前版本
#Copyright (C):     2020 All rights reserved
#********************************************************************

#支持在线和离线安装Jenkins,内存建议4G以上

JENKINS_VERSION=2.440.1
#JENKINS_VERSION=2.426.2
#JENKINS_VERSION=2.414.2
#JENKINS_VERSION=2.401.1
#JENKINS_VERSION=2.375.2
#JENKINS_VERSION=2.346.2
#JENKINS_VERSION=2.319.3
#JENKINS_VERSION=2.303.3
#JENKINS_VERSION=2.289.3

JENKINS_FILE=jenkins_${JENKINS_VERSION}_all.deb
URL="https://mirrors.tuna.tsinghua.edu.cn/jenkins/debian-stable/jenkins_${JENKINS_VERSION}_all.deb"
#URL="https://mirrors.aliyun.com/jenkins/debian-stable/jenkins_${JENKINS_VERSION}_all.deb"
#URL="https://mirrors.aliyun.com/jenkins/debian-stable/jenkins_2.303.2_all.deb"
#URL="https://mirrors.tuna.tsinghua.edu.cn/jenkins/debian-stable/jenkins_2.289.3_all.deb"
#URL="https://mirrors.aliyun.com/jenkins/debian-stable/jenkins_2.289.3_all.deb"
#URL="https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.289.3-1.1.noarch.rpm"

GREEN="echo -e \E[32;1m"
END="\E[0m"

HOST=`hostname -I|awk '{print $1}'`
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


install_jdk() {
    java -version &>/dev/null && { color "JDK 已安装!" 1 ; return;  }
    if command -v yum &>/dev/null ; then
        yum -y install java-1.8.0-openjdk-devel || { color "安装JDK失败!" 1; exit 1; }
    elif command -v apt &>/dev/null ; then
        apt update
        apt install openjdk-11-jdk -y || { color "安装JDK失败!" 1; exit 1; } 
        #apt install openjdk-8-jdk -y || { color "安装JDK失败!" 1; exit 1; }
    else
        color "不支持当前操作系统!" 1
        exit 1
    fi
    java -version && { color "安装 JDK 完成!" 0 ; } || { color "安装JDK失败!" 1; exit 1; }
}


install_jenkins() {
    if [ ! -e ${JENKINS_FILE} ];then
        wget  $URL || { color  "下载失败!" 1 ;exit ; }
    fi
    if [ $ID = "centos" -o $ID = "rocky" ];then
        yum -y install ${JENKINS_FILE}
    else 
        apt -y install daemon net-tools || { color  "安装依赖包失败!" 1 ;exit ; }
        dpkg -i  ${URL##*/} 
    fi
    
#    if [ $? -eq 0 ];then
#       color "安装Jenkins完成!" 0
#    else
#       color "安装Jenkins失败!" 1
#       exit
#    fi
}


start_jenkins() { 
    systemctl enable --now jenkins
    while :;do
        [ -f /var/lib/jenkins/secrets/initialAdminPassword ] && \
        { key=`cat /var/lib/jenkins/secrets/initialAdminPassword` ; break; }
        sleep 1
    done
    color "Jenkins安装完成!" 0
    echo "-------------------------------------------------------------------"
    echo -e "访问链接: \c"
    ${GREEN}"http://$HOST:8080/"${END}
    echo -e "登录秘钥: \c"
    ${GREEN}$key${END}
}


install_jdk

install_jenkins

start_jenkins
