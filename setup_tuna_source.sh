#!/bin/bash

# 获取操作系统信息
if [[ -f /etc/redhat-release ]]; then
    OS=centos
elif [[ -f /etc/lsb-release ]]; then
    OS=ubuntu
elif [[ -f /etc/debian_version ]]; then
    OS=debian
else
    echo "不支持的操作系统类型。"
    exit 1
fi

# 配置清华大学源
if [[ "$OS" == "centos" ]]; then
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.tuna.tsinghua.edu.cn/help/CentOS-Base.repo.txt
    yum makecache
elif [[ "$OS" == "ubuntu" ]]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    echo "# 清华大学" > /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse" >> /etc/apt/sources.list
    apt-get update
elif [[ "$OS" == "debian" ]]; then
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    echo "# 清华大学" > /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $(cat /etc/debian_version | cut -d '.' -f 1) main contrib non-free" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $(cat /etc/debian_version | cut -d '.' -f 1)-updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $(cat /etc/debian_version | cut -d '.' -f 1)-backports main contrib non-free" >> /etc/apt/sources.list
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ $(cat /etc/debian_version | cut -d '.' -f 1)/updates main contrib non-free" >> /etc/apt/sources.list
    apt-get update
else
    echo "不支持的操作系统类型。"
    exit 1
fi

echo "源已成功配置为清华大学源。"