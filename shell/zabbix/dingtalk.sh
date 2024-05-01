#!/bin/bash
#
#********************************************************************
#Author:            lixijun
#QQ:                505697096
#Date:              2022-11-01
#FileName:          dingtalk.sh
#Description:       The test script
#Copyright (C):     2022 All rights reserved
#********************************************************************

#此脚本支持自定义关键词和加签和的消息发送

#参考帮助：https://open.dingtalk.com/document/robots/customize-robot-security-settings

WEBHOOK_URL="https://oapi.dingtalk.com/robot/send?access_token=c41b24fc7d4ba12fbb3fa180cd6df6bf4576afc4597d2b3bf54c3ee12aabf4a8"
#WEBHOOK_URL="https://oapi.dingtalk.com/robot/send?access_token=9b31a61e017e6c30c2e875f192b32c76118482d80036a8f213c0b166e0855093"

YOUR_SECRET="SEC1e7eb98482160ea42135491cb62fe46076150aaf810ee9e566806d73e501fcaf"
#YOUR_SECRET="SEC478dba31d8609ef07dc4e3f47c373210413524f7fb1787178267f8c794969546"



# 检查参数数量
if [ "$#" -ne 3 ]; then
  echo "使用方法: $0 <收信人手机号> <主题> <消息内容>"
  exit 1
fi

# 从参数中获取值
receiver_phone="$1"
subject="$2"
message="$3"

# 配置DingTalk Webhook URL
webhook_url="https://oapi.dingtalk.com/robot/send?access_token=${YOUR_ACCESS_TOKEN}"

# 编码 URL
function url_encode() {
    t="${1}"
    if [[ -n "${1}" && -n "${2}" ]];then
       if ! echo 'xX' | grep -q "${t}";then
          t='x'
       fi
       echo -n "${2}" | od -t d1 | awk -v a="${t}" '{for (i = 2; i <= NF; i++) {printf(($i>=48 && $i<=57) || ($i>=65 &&$i<=90) || ($i>=97 && $i<=122) ||$i==45 || $i==46 || $i==95 || $i==126 ?"%c" : "%%%02"a, $i)}}'
   else
       echo -e '$1 and $2 can not empty\n$1 ==> 'x' or 'X', x ==> lower, X ==> toupper.\n$2 ==> Strings need to url encode'
   fi
}

function dingrobot(){
    # 生成时间戳和随机字符串
    timestamp=$(date +%s%3N)
    dingrobot_sign=$(echo -ne "${timestamp}\n${YOUR_SECRET}" | openssl dgst -sha256 -hmac "${YOUR_SECRET}" -binary | base64)
    dingrobot_sign=$(url_encode 'X' "${dingrobot_sign}")
    post_url="${WEBHOOK_URL}&timestamp=${timestamp}&sign=${dingrobot_sign}"

    # 构建JSON数据
    json_data="{
        \"msgtype\": \"text\",
        \"text\": {
             \"content\": \"$subject\n$message\"
        },
        \"at\": {
            \"atMobiles\": [\"$receiver_phone\"]
        }
    }"

    # 发送HTTP POST 请求至 DingTalk Webhook，包括签名信息
    curl -s -X POST -H "Content-Type: application/json"  -d "$json_data" "${post_url}"

    # 检查是否发送成功
    if [ $? -eq 0 ]; then
        echo "通知发送成功!"
    else
        echo "通知发送失败!"
    fi
}

dingrobot

