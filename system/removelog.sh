#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "请以 root 身份运行此脚本。例如：sudo $0"
    exit
fi

# 定义日志目录路径
LOG_DIR="/var/log"
LOG_FILE="/var/log/removelog.log"

# 检查日志目录是否存在
if [ -d "$LOG_DIR" ]; then
    # 使用find命令查找所有.gz文件，并执行删除操作
    find "$LOG_DIR" -name "*.gz" -exec rm -f {} \;
    echo "$(date '+%Y-%m-%d %H:%M:%S') 所有.gz文件已被删除。" >> "$LOG_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') 日志目录 $LOG_DIR 不存在。" >> "$LOG_FILE"
fi

