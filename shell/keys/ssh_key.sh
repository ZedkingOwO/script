#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2024-03-26
#FileName:          key-scp.sh
#*********************************************************************


apt install sshpass #安装sshpass命令⽤于同步公钥到各k8s服务器
ssh-keygen -t rsa-sha2-512 -b 4096



IP=" #⽬标主机列表
10.0.0.201
10.0.0.202
"

REMOTE_PORT="22"
REMOTE_USER="root"
REMOTE_PASS="123456"

for REMOTE_HOST in ${IP};do
	REMOTE_CMD="echo ${REMOTE_HOST} is successfully!"
    #添加⽬标远程主机的公钥(连接对方 并输入YES)
	ssh-keyscan -p "${REMOTE_PORT}" "${REMOTE_HOST}" >> ~/.ssh/known_hosts
	#通过sshpass配置免秘钥登录、并创建python3软连接
	sshpass -p "${REMOTE_PASS}" ssh-copy-id "${REMOTE_USER}@${REMOTE_HOST}"
	ssh ${REMOTE_HOST} ln -sv /usr/bin/python3 /usr/bin/python #必须v都要做包括本机
	echo ${REMOTE_HOST} 免秘钥配置完成!
done