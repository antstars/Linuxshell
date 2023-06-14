#!/bin/bash

# 检查当前用户是否为 root 用户，如果不是则退出脚本
if [[ $(id -u) -ne 0 ]]; then
  echo "请以 root 用户身份运行脚本"
  exit 1
fi

# 安装中文语言支持
if [[ -f /etc/debian_version ]]; then  # 如果是 Debian 或 Ubuntu
  apt update && apt install -y language-pack-zh-hans language-pack-gnome-zh-hans
elif [[ -f /etc/redhat-release ]]; then  # 如果是 Red Hat 或 CentOS
  yum install -y kde-l10n-Chinese glibc-common
  localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
  echo "LANG=zh_CN.utf8" > /etc/locale.conf
else
  echo "未知的 Linux 发行版，无法设置语言"
  exit 1
fi

# 重启系统，使语言设置生效
echo "语言设置已生效，请重启系统"
