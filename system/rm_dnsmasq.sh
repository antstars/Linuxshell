#!/bin/bash
##用于删除dnsmasq防止占用53端口

if [ "$EUID" -ne 0 ]; then
    echo "请以 root 身份运行此脚本。例如：sudo $0"
    exit
fi

if [ ! -n "$(lsof -i :53)" ]; then
    echo "目前53端口程序： $(lsof -i :53 | awk 'NR==2 {print $1}')"
else
    echo "53端口未被占用！"
    exit 0
fi