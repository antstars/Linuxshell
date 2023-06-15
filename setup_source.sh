#!/bin/bash

# 检查当前用户是否为root用户
if [[ $EUID -ne 0 ]]; then
   echo "请使用root用户执行该脚本。"
   exit 1
fi

# 获取操作系统信息
if [ -f /etc/os-release ]; then
    . /etc/os-release
    #echo "当前操作系统为：$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2)"
    echo "当前操作系统为：$ID"
else
    echo "无法获取操作系统信息。"
    exit 1
fi

# 定义源列表
sources=(
    "中科大源: mirrors.ustc.edu.cn"
    "清华源: mirrors.tuna.tsinghua.edu.cn"
    "阿里源: mirrors.aliyun.com"
)
# 输出可选源列表
echo "可选源列表："
for ((i=0; i<${#sources[@]}; i++)); do
    echo "$(($i+1)). ${sources[$i]}"
done
# 用户选择源
read -p "请输入要选择的源的编号： " choice

# 检查选择的编号是否合法
if ! [[ "$choice" =~ ^[1-${#sources[@]}]$ ]]; then
    echo "无效的选择。"
    exit 1
fi
# 根据选择的源，设置相应的源配置
case "$choice" in
    1)
        echo "正在使用中科大源..."
        source_url="mirrors.ustc.edu.cn"
        ;;
    2)
        echo "正在使用清华源..."
        source_url="mirrors.tuna.tsinghua.edu.cn"
        ;;
    3)
        echo "正在使用阿里源..."
        source_url="mirrors.aliyun.com"
        ;;
    *)
        echo "无效的选择。"
        exit 1
        ;;
esac
# 更新系统源配置
if [ "$ID" == "ubuntu" ] || [ "$ID" == "debian" ]; then
    sources_file="/etc/apt/sources.list"
elif [ "$ID" == "centos" ]; then
    sources_file="/etc/yum.repos.d/CentOS-Base.repo"
else
    echo "不支持的操作系统。"
    exit 1
fi

# 备份原有源配置文件
cp "$sources_file" "$sources_file.bak"

# 更新源配置文件
sed -i "s|https://[a-zA-Z0-9.-]*/|https://$source_url/|g" "$sources_file"
sed -i "s|http://[a-zA-Z0-9.-]*/|https://$source_url/|g" "$sources_file"

echo "源配置已更新为 $source_url"
echo "请运行 'apt update' 或 'yum makecache' 更新软件包列表。"
