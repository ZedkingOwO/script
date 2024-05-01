#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2020-02-18
#FileName:          install_sonarqube.sh
#Description:       The test script
#Copyright (C):     2020 All rights reserved
#********************************************************************

#SONARQUBE从9.9版本以后要求安装JDK17

#支持在线和离线安装，在线下载可能很慢,建议离线安装

SONARQUBE_VER="9.9.4.87374"
#SONARQUBE_VER="9.9.3.79811"
#SONARQUBE_VER="9.9.2.77730"
#SONARQUBE_VER="9.9.1.69595"
#SONARQUBE_VER="9.9.0.65466"
#SONARQUBE_VER="8.9.10.61524"
#SONARQUBE_VER="8.9.9.56886"
#SONARQUBE_VER="8.9.2.46101"
#SONARQUBE_VER="7.9.2"

SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VER}.zip"
SONAR_USER=sonarqube
SONAR_USER_PASSWORD=123456

WORK_DIR=`pwd`
HOST=`hostname -I|awk '{print $1}'`

GREEN="echo -e \E[32;1m"
END="\E[0m"

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
        apt install openjdk-17-jdk -y || { color "安装JDK失败!" 1; exit 1; } 
        #apt install openjdk-11-jdk -y || { color "安装JDK失败!" 1; exit 1; } 
        #apt install openjdk-8-jdk -y || { color "安装JDK失败!" 1; exit 1; }
    else
        color "不支持当前操作系统!" 1
        exit 1
    fi
    java -version && { color "安装 JDK 完成!" 0 ; } || { color "安装JDK失败!" 1; exit 1; }
}

system_prepare () {
    useradd -s /bin/bash -m sonarqube 
    cat >> /etc/sysctl.conf <<EOF
vm.max_map_count=524288
fs.file-max=131072
EOF
    sysctl -p
    cat >> /etc/security/limits.conf  <<EOF
sonarqube  -  nofile 131072
sonarqube  -  nproc  8192
EOF
}

install_postgresql(){
    if [ $ID = "centos" -o $ID = "rocky" ];then
        if [ $VERSION_ID -eq 7 ];then
            rpm -i http://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            yum -y install postgresql12-server postgresql12 postgresql12-libs
            postgresql-12-setup --initdb
        else
            #rpm -i http://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            color "不支持此操作系统!" 1
            exit 
        fi
        systemctl enable  postgresql.service
        systemctl start  postgresql.service
    else 
        apt update
        apt -y install postgresql
    fi
    if [ $? -eq 0 ];then
       color "安装postgresql完成!" 0
    else
       color "安装postgresql失败!" 1
       exit
    fi
}


config_postgresql () {
    if [ $ID = "centos" -o $ID = "rocky" ];then
        sed -i.bak "/listen_addresses/a listen_addresses = '*'"  /var/lib/pgsql/data/postgresql.conf
        cat >>  /var/lib/pgsql/data/pg_hba.conf <<EOF
host    all             all             0.0.0.0/0               md5
EOF
    else 
        sed -i.bak "/listen_addresses/c listen_addresses = '*'" /etc/postgresql/1*/main/postgresql.conf 
        cat >>  /etc/postgresql/*/main/pg_hba.conf <<EOF
host    all             all             0.0.0.0/0               md5
EOF
    fi
    systemctl restart postgresql
    
    su - postgres -c "psql -U postgres <<EOF
CREATE USER $SONAR_USER WITH ENCRYPTED PASSWORD '$SONAR_USER_PASSWORD';
CREATE DATABASE sonarqube ;
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO $SONAR_USER;
EOF"
}

install_sonarqube() {
    cd $WORK_DIR
    if [ -f sonarqube-${SONARQUBE_VER}.zip ] ;then
        mv sonarqube-${SONARQUBE_VER}.zip /usr/local/src
    else
        wget -P /usr/local/src ${SONARQUBE_URL}  || { color  "下载失败!" 1 ;exit ; }
    fi
    cd /usr/local/src
    unzip ${SONARQUBE_URL##*/}
    ln -s /usr/local/src/sonarqube-${SONARQUBE_VER} /usr/local/sonarqube
    chown -R sonarqube.sonarqube /usr/local/sonarqube/
    cat > /lib/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=simple
User=sonarqube
Group=sonarqube
PermissionsStartOnly=true
ExecStart=/usr/bin/nohup /usr/bin/java -Xms32m -Xmx32m -Djava.net.preferIPv4Stack=true -jar /usr/local/sonarqube/lib/sonar-application-${SONARQUBE_VER}.jar
StandardOutput=syslog
LimitNOFILE=65536
LimitNPROC=8192
TimeoutStartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    cat >> /usr/local/sonarqube/conf/sonar.properties <<EOF
sonar.jdbc.username=$SONAR_USER
sonar.jdbc.password=$SONAR_USER_PASSWORD
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
EOF
}

start_sonarqube() { 
    systemctl enable --now   sonarqube.service 
    systemctl is-active sonarqube
    if [ $?  -eq 0 ];then  
        echo 
        color "sonarqube 安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        ${GREEN}"http://$HOST:9000/"${END}
        echo -e "用户和密码: \c"
        ${GREEN}"admin/admin"${END}
    else
        color "sonarqube 安装失败!" 1
        exit
    fi
}

install_jdk

system_prepare

install_postgresql

config_postgresql

install_sonarqube

start_sonarqube


