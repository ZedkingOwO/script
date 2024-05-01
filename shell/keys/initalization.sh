#!/bin/bash
#
#----------------------------------------------------------------
#Author:			          joker
#QQ:          	 	          505697096
#Date:                        2023-12-10
#Filename:                    initalization.sh
#
#----------------------------------------------------------------
#


debian(){  
    #设置主机名
    hostnamectl set-hostname ubuntu

    #设置PS1
    PS11=PS1="'"\[\e[1;35m\][\u@\h \W]\$ \[\e[0m\]"'"
    echo  $PS11   >> /root/.bashrc 

    #关闭防火墙
    systemctl disable --now  ufw.service

    #重新设置网卡名称
    sed -i 's/GRUB_CMDLINE_LINUX=".*"/GRUB_CMDLINE_LINUX="net.ifnames=0"/g' /etc/default/grub

    #永久关闭swap分区
    sed -i '/swap/s/^/#/' /etc/fstab
    #有些设置需要重启生效
    reboot 
    }




rhel(){
    
    #设置主机名
    hostnamectl set-hostname ubuntu

    #设置PS1
    PS111=PS1="'"\[\e[1;35m\][\u@\h \W]\$ \[\e[0m\]"'"
    echo  $PS11   >> /root/.bashrc

    #关闭防火墙
    systemctl disable --now firewalld

    #关闭Selinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

    #重设网卡名称


    #永久关闭swap分区


    #重启生效
    reboot
    }



. /etc/os-release

if   [ $ID = ubuntu ];then
     debian
elif [[ $ID =~ rocky|centos|rhel ]];then
     rhel
else
    echo "不是哥们 什么垃圾系统阿"
    exit 404
fi
