#!/bin/bash
##下载安装node_exporter

## 变量定义
node_dir=/etc/prometheus/exporter
node_file=/etc/prometheus/exporter/node_exporter

## 报错退出
function Output_Error() {
    [ "$1" ] && echo -e "\n$1\n"
    exit 1
}

## 权限判定
function PermissionJudgment() {
    if [ "$EUID" -ne 0 ]; then
    Output_Error "请以 root 身份运行此脚本。例如：sudo $0"
    fi
}

## 检查包管理器类型
function CheckPackageManager() {
    # 检查 apt 命令是否存在
    if type -p apt &> /dev/null; then
        PackageManage="apt"
        PnstallerSuffix="deb"
        InstallCommand="dpkg -i"
    elif type -p apt-get &> /dev/null; then
        PackageManage="apt-get"
        PnstallerSuffix="deb"
        InstallCommand="dpkg -i"
    # 检查 yum 命令是否存在
    elif type -p yum &> /dev/null; then
        PackageManage="yum"
        PnstallerSuffix="rpm"
        InstallCommand="yum install -y"
    # 检查 dnf 命令是否存在
    elif type -p dnf &> /dev/null; then
        PackageManage="dnf"
        PnstallerSuffix="rpm"
        InstallCommand="dnf install -y"
    # 检查 pacman 命令是否存在
    elif type -p pacman &> /dev/null; then
        PackageManage="pacman"
        PnstallerSuffix="pkg.tar.xz"
    # 检查 zypper 命令是否存在
    elif type -p zypper &> /dev/null; then
        PackageManage="zypper"
        PnstallerSuffix="rpm"
        InstallCommand="rpm -Uvh"
    # 检查 apk 命令是否存在
    elif type -p apk &> /dev/null; then
        PackageManage="apk"
        PnstallerSuffix="apk"
    else 
        Output_Error "不支持的包管理器类型！！！"
    fi
}

## 检查并安装命令
function InstallCommandIfMissing() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "未安装 $cmd，正在安装..."
        $PackageManage install -y "$cmd"
        echo "已成功安装 $cmd!"
    fi
}
function CheckCommand() {
    InstallCommandIfMissing curl
    InstallCommandIfMissing wget
}

## 判定系统处理器架构，软件包采用变量：$SOURCE_ARCH
function CheckArch() {
    case $(uname -m) in
    x86_64)
        SYSTEM_ARCH="x86_64"
        SOURCE_ARCH="amd64"
        ;;
    aarch64)
        SYSTEM_ARCH="ARM64"
        SOURCE_ARCH="arm64"
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
}

function node_exporter_dir_check(){
    
    if [ ! -d ${node_dir} ]; then
        mkdir -p ${node_dir}
    fi

}

function download_start() {
    download_url=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "browser_download_url.*linux-${SOURCE_ARCH}" | cut -d '"' -f 4)
    node_version=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [ ! -d ${node_dir} ]; then
        mkdir -p ${node_dir}
        echo "创建工作目录：${node_dir}"
    fi

    wget -O ${node_dir}${node_dir}.tar.gz ${download_url} 

}



function main() {
    PermissionJudgment
    CheckPackageManager
    CheckCommand
    CheckArch
    node_exporter_dir_check
    download_start
}

main