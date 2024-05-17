#!/bin/bash
###更新docker后有些服务会停止，需要执行重启，此脚本实现自动化重启###
###写入定时任务每两分钟执行一次：*/2 * * * * {path}/docker_exited_restart.sh

# 检查是否以管理员权限运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "必须以 root 或 sudo 身份运行此脚本。"
    exit 1
fi

exited_container=$(docker ps -a | grep Exited | awk '{print $1}')

for container_id in ${exited_container}; do
    if [ -n "${exited_container}" ]; then
        docker restart ${container_id}
        container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's,^/,,')
        echo "$(date '+%Y-%m-%d %H:%M:%S') 容器：${container_name} 已重启" >> /var/log/docker_exited_restart.log
        sleep 2 #避免docker同时重启产生的问题
    fi
done

