#!/bin/bash

# 检查是否以管理员权限运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "必须以 root 或 sudo 身份运行此脚本。"
    exit 1
fi
## 报错退出
function Output_Error() {
    [ "$1" ] && echo -e "\n $1 \n"
    exit 1
}
# 设置下载目录和文件名
download_dir="/etc/prometheus/cadvisor"
cadvisor_file="cadvisor"

if [ ! -d ${download_dir} ]; then
    mkdir -p ${download_dir}
fi

# 获取当前 CPU 架构
cpu_arch=$(uname -m)

# 根据 CPU 架构选择对应的发布包文件名
case "$cpu_arch" in
  "arm64")
    release_file="linux_arm64"
    ;;
  "x86_64")
    release_file="linux_amd64"
    ;;
  *)
    echo "不支持的 CPU 架构：$cpu_arch"
    exit 1
    ;;
esac

# 获取最新版本的 CoreDNS 的下载链接
downloadurl=$(curl -s https://api.github.com/repos/google/cadvisor/releases/latest | grep "browser_download_url.*-linux-${release_file}" | grep -v ".sha256" | cut -d '"' -f 4)

function CheckPortOccupancy() {
  if pgrep -x cadvisor > /dev/null; then
    echo "程序已在运行，结束程序"
    exit 1
  else
    echo "检测到cadvisor程序未在运行，继续执行"
  fi

  if lsof -i :8080 > /dev/null; then
      echo "安装失败！！！ 端口8080已被占用。"
      Output_Error "占用端口的进程：$(lsof -i :8080 | awk 'NR==2 {print $1}')"
  fi
}

function downloadcadvisor() {
  if [ ! -f ${download_dir}${cadvisor_file} ]; then
      curl -o ${download_dir}${cadvisor_file} ${downloadurl}
      echo "文件已下载完成：${download_dir}${cadvisor_file}"
  else
      echo "文件已存在!!!"
  fi
}

function Startcadvisor() {
  if [ ! -f /etc/systemd/system/cadvisor.service ]; then
  cat >/etc/systemd/system/cadvisor.service << EOF
[Unit]
Description=cAdvisor
Documentation=https://github.com/google/cadvisor
After=network.target

[Service]
# Type设置为notify时，服务会不断重启
# 关于type的设置，可以参考https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options
Type=simple
User=root
Group=root
# 指定运行端口和读取的配置文件
ExecStart=/etc/prometheus/cadvisor
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF
  fi

#启动服务
  systemctl daemon-reload
  systemctl start cadvisor.service
  systemctl enable cadvisor.service

#检查服务状态
  if [ ${systemctl is-active cadvisor.service} == "active" ]; then
      echo "安装完成，服务状态：${systemctl is-active cadvisor.service}"
  else
      echo "安装失败!!!请检查...服务状态：${systemctl is-active cadvisor.service}"
  fi

  if [ ${systemctl is-enabled cadvisor.service} == "enabled" ]; then
      echo "服务设置开机自启，服务状态：${systemctl is-enabled cadvisor.service}"
  else
      echo "服务设置开机自启失败！！！请检查...服务状态：${systemctl is-enabled cadvisor.service} "
  fi
}

#主函数
function main() {
  CheckPortOccupancy
  downloadcadvisor
  Startcadvisor
  exit 0
}

main