#!/bin/bash
##自动下载安装及更新docker-compose#####

## 定义全局变量
githubrepos=docker/compose
## 报错退出
function Output_Error() {
    [ "$1" ] && echo -e "\n $1\n"
    exit 1
}

## 权限判定
function PermissionJudgment() {
    if [ $UID -ne 0 ]; then
        Output_Error "权限不足，请使用 Root 用户运行本脚本"
    fi
}
## 判定系统处理器架构
function CheckArch() {
    case $(uname -m) in
    x86_64)
        SYSTEM_ARCH="x86_64"
        SOURCE_ARCH="x86_64"
        ;;
    aarch64)
        SYSTEM_ARCH="ARM64"
        SOURCE_ARCH="aarch64"
        ;;
    armv7l)
        SYSTEM_ARCH="ARMv7"
        SOURCE_ARCH="armv7"
        ;;
    armv6l)
        SYSTEM_ARCH="ARMv6"
        SOURCE_ARCH="armv6"
        ;;
    i386 | i686)
        Output_Error "不支持x86_32架构的环境!"
        ;;
    *)
        Output_Error "不支持的架构环境!"
        ;;
    esac
    downloadurl=$(curl -s https://api.github.com/repos/${githubrepos}/releases/latest | grep "browser_download_url.*-linux-${SOURCE_ARCH}" | grep -v ".sha256" | cut -d '"' -f 4)
}
## 检查版本
function CheckVersion() {
    if [ -x /usr/local/bin/docker-compose ]; then
        old_version=$(/usr/local/bin/docker-compose --version | awk '{print $4}')
        new_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        if [[ "${old_version}" == "${new_version}" ]]; then
            read -p "检测到已安装最新版本${old_version}，是否取消安装 [Y/n]" INPUT
            [[ -z $INPUT ]] && INPUT=Y
            case $INPUT in
            [Yy] | [Yy][Ee][Ss])
            exit 0
            ;;
            [Nn] | [Nn][Oo])
            DownloadInstall
            exit 0
            ;;
            *)
            Output_Error "输入错误，默认不覆盖安装！"
            ;;
            esac
        else
            read -p "已安装旧版本${old_version}，新版本号为${new_version}，是否更新版本 [Y/n]" INPUT
            [[ -z $INPUT ]] && INPUT=Y
            case $INPUT in
            [Yy] | [Yy][Ee][Ss])
            DownloadInstall
            exit 0
            ;;
            [Nn] | [Nn][Oo])
            exit 0
            ;;
            *)
            Output_Error "输入错误，默认不覆盖安装！"        
            ;;
            esac
        fi
        return
    fi
}
## 下载安装
function DownloadInstall() {
    wget -O /usr/local/bin/docker-compose ${downloadurl}
    chmod +x /usr/local/bin/docker-compose
    if [ -f /usr/bin/docker-compose ]; then
        rm /usr/bin/docker-compose
    fi
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "已成功安装 $(docker-compose --version)"
}
function main() {
    PermissionJudgment
    CheckArch
    CheckVersion
    DownloadInstall
}
main

