#!/bin/bash

# 检查是否以管理员权限运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "必须以 root 或 sudo 身份运行此脚本。"
    exit 1
fi

if pgrep -x coredns > /dev/null; then
    echo "程序已在运行，结束程序"
    exit 1
else
    echo "检测到coredns程序未在运行，继续执行"
fi
# 设置下载目录和文件名
download_dir="/etc/coredns"
coredns_file="coredns"

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

# 检查下载目录是否存在
if [ ! -d "$download_dir" ]; then
    echo "创建下载目录：$download_dir"
    mkdir -p "$download_dir"
fi

# 检查下载目录是否非空
if [ "$(ls -A "${download_dir}")" ]; then
    echo "Download directory is not empty."
    read -p "您想覆盖现有文件吗？ (y/n): " overwrite_option
  if [[ "$overwrite_option" =~ ^[Yy]$ ]]; then
      echo "覆盖现有文件。"
  else
      echo "终止。现有文件不会被覆盖"
      exit 0
  fi
fi

# 获取最新版本的 CoreDNS 的下载链接
release_url="https://github.com/coredns/coredns/releases/download/v1.11.1/coredns_1.11.1_$release_file.tgz"

# 下载最新版本的 CoreDNS
echo "正在下载 CoreDNS..."
curl -L -o "${download_dir}/${coredns_file}.tgz" "$release_url"

# 判断下载是否成功
if [ $? -eq 0 ]; then
    echo "下载完成。"

  # 解压
    echo "正在解压 CoreDNS..."
    tar -xzvf "${download_dir}/${coredns_file}.tgz" -C "${download_dir}/"

  # 删除压缩包
    rm "${download_dir}/${coredns_file}.tgz"

    echo "CoreDNS 下载完成。"
else
    echo "下载失败。请检查您的互联网连接，然后重试。"
fi
#检查coredns执行文件权限
if [ -x ${download_dir}/coredns ]; then
    echo "文件可执行，正在写入配置文件"
else
    echo "文件不可执行，正在赋予执行权限"
    chmod +x ${download_dir}/coredns
fi
#写入默认配置文件Corefile，默认转发到阿里tls-dns
cat << EOF > $download_dir/Corefile
.:1053 {
    forward . tls://223.5.5.5:853 tls://223.6.6.6:853 {
        tls_servername dns.alidns.com
      }
    health :8100
    reload 5s
    prometheus :9153
    cache 30
    errors
    whoami
    log
}
EOF

#写入systemd启动文件
cat << EOF > /etc/systemd/system/coredns.service
[Unit]
Description=CoreDNS
Documentation=https://coredns.io/manual/toc/
After=network.target

[Service]
# Type设置为notify时，服务会不断重启
# 关于type的设置，可以参考https://www.freedesktop.org/software/systemd/man/systemd.service.html#Options
Type=simple
User=root
Group=root
# 指定运行端口和读取的配置文件
ExecStart=/etc/coredns/coredns -dns.port=1053 -conf /etc/coredns/Corefile
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

Corefile="/etc/coredns/Corefile"
if [ -e "$Corefile" ]; then
    echo "Corefile文件写入完成"
else
    echo "Corefile文件写入失败"
    exit 1
fi

service_file="/etc/systemd/system/coredns.service"
if [ -e "$service_file" ]; then
    echo "$service_file文件存在"
else
    echo "$service_file文件不存在"
    exit 1
fi

#systemd重载
systemctl daemon-reload
#启动coredns
systemctl start coredns.service
#开启coredns自启动
systemctl enable coredns.service

coredns="coredns"
if ps -A | grep -q "$coredns"; then
    echo "Coredns安装完成并设置自启"
else
    echo "程序 $coredns 未在执行,脚本结束"
    exit 1
fi


