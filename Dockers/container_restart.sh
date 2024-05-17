#!/bin/bash
###计算exitd状态超过5min的container并restart
###写入定时任务每两分钟执行一次：*/2 * * * * {path}/container_restart.sh

# 检查是否以管理员权限运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "必须以 root 或 sudo 身份运行此脚本。"
    exit 1
fi

LOG_FILE="/var/log/container_restart.log"

# 检查日志文件写入权限
if [ ! -w "$LOG_FILE" ]; then
    echo "无法写入日志文件：$LOG_FILE"
    exit 1
fi

# 获取当前时间戳
current_time=$(date +%s)

# 检查容器的退出状态
check_container_exit_status() {
  container_id=$1
  exit_status=$(docker inspect --format='{{.State.ExitCode}}' "$container_id")

  # 检查退出状态是否为非零值
  if [ "$exit_status" != "0" ]; then
    # 获取容器的停止时间戳
    stop_time=$(docker inspect --format='{{.State.FinishedAt}}' "$container_id")
    stop_timestamp=$(date -d "$stop_time" +%s)

    # 计算容器停止的持续时间（以秒为单位）
    duration=$((current_time - stop_timestamp))

    # 如果容器停止时间超过5分钟，则重启容器并记录日志
    if [ $duration -gt 300 ]; then
      container_name=$(docker inspect --format '{{.Name}}' "$container_id" | sed 's,^/,,')
      docker restart "$container_id"
      echo "$(date '+%Y-%m-%d %H:%M:%S')重启容器: $container_name" >> "$LOG_FILE"
      sleep 2 #避免docker同时重启产生的问题
    fi
  fi
}

# 获取所有容器的ID列表
container_ids=$(docker ps -aq)

# 循环检查每个容器的退出状态并重启
for container_id in $container_ids; do
  check_container_exit_status "$container_id"
done
