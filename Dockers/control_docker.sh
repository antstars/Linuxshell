#!/bin/bash

##########功能：快捷进入、更改、删除docker,查询docker日志###########
# 颜色定义
red='\033[0;31m'        # 红色
# 重置样式
color_reset='\033[0m'         # 重置样式为默认值

## 报错退出
function Output_Error() {
    [ "$1" ] && echo -e "\n $1 \n"
    exit 1
}

## 权限判定
function PermissionJudgment() {
    if [ $UID -ne 0 ]; then
        Output_Error "权限不足，请使用 Root 用户运行本脚本"
    fi
}

## 进入docker内部
function exec_docker() {
    echo "请选择要连接的容器："
    containers=$(docker ps --format "{{.Names}}")

    digital=1
    for container in $containers;do
        echo "$digital:$container"
        ((digital++))
    done

    #读取用户输入的编号
    read -p "请输入容器编号:" container_number
    if ! [[ "$container_number" =~ ^[1-9][0-9]*$ ]] || (( container_number < 1 || container_number > digital-1 )); then
        echo "输入的编号无效，请输入正确的容器编号！"
        exec_docker
    fi
    #根据用户输入的编号获取对应容器的变量名
    container_variable=$(echo "$containers" | awk "NR==$container_number")

    #运行docker exec命令连接到用户选择的容器
    docker exec -it "$container_variable" bash
}

## 更新容器信息
function update_docker() {
    echo "请选择要更新的容器："
    containers=$(docker ps --format "{{.Names}}")

    digital=1
    for container in $containers;do
        echo "$digital:$container"
        ((digital++))
    done

    #读取用户输入的编号
    read -p "请输入容器编号:" container_number
    #根据用户输入的编号获取对应容器的变量名
    container_variable=$(echo "$containers" | awk "NR==$container_number")
    echo "请输入需要更新的内容"
    echo "1. 更新CPU限制数"
    echo "2. 更新内存限制"
    echo "3. 更新重启策略" 
    read -p "请输入数字执行响应的功能[1-3]: " operate
    case $operate in
        1)
        ## 计算总CPU数
        cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
        read -p "请输入CPU限制数量：" cpus
        if ! (($cpus >= 1 && $cpus <= $cpu_cores)); then
            echo "输入错误，返回上一级"
            update_docker
        fi
        docker update --cpus $cpus ${container_variable}
        echo "已更新! "
        ;;
        2)
        ## 计算总物理内存（M）
        total_ram=$(free -m | awk '/^Mem:/{print $2}')
        read -p "请输入内存值，128-${total_ram}之间(M)：" mem
        if ! (($mem >= 128 && $mem <= $total_ram )); then
            echo "输入错误，返回上一级"
            update_docker
        fi
        docker update -m ${mem}m --memory-swap -1 ${container_variable}
        echo "已更新! "
        ;;
        3)
        echo "1. no(默认):容器退出后不会自动重启"
        echo "2. always:容器退出后自动重启。无论退出的原因是什么(例如手动停止、错误退出或容器崩溃),Docker 都会尝试自动重新启动容器"
        echo "3. on-failure[:max-retries]：容器退出时，只有在退出状态码非零的情况下才会自动重启。可选参数 max-retries 指定最大重试次数"
        echo "4. unless-stopped:容器退出后自动重启,除非显式停止容器。即使在主机重启后,Docker 服务重新启动时，该容器也会自动启动。"
        read -p "请输入重启策略编号：" restart_strategy
        case $restart_strategy in
            1)
            docker update --restart no ${container_variable}
            echo "已更新! "
            ;;
            2)
            docker update --restart always ${container_variable}
            echo "已更新! "
            ;;
            3)
            docker update --restart on-failure ${container_variable}
            echo "已更新! "
            ;;
            4)
            docker update --restart unless-stopped ${container_variable}
            echo "已更新! "
            ;;
            *)
            echo "输入错误，返回上一级"
            update_docker
            ;;
        esac
        ;;
        *)
        echo "输入错误，返回上一级"
        Options
        ;;

    esac
}

## 删除容器
function delete_docker() {
    echo "请选择要删除的容器："
    containers=$(docker ps --format "{{.Names}}")

    digital=1
    for container in $containers; do
        echo "$digital:$container"
        ((digital++))
    done

    #读取用户输入的编号
    read -p "请输入容器编号:" container_number
    # 判断用户输入的数字是否有效
    if ! [[ "$container_number" =~ ^[1-9][0-9]*$ ]] || (( container_number < 1 || container_number > digital-1 )); then
        Output_Error "输入的编号无效，请输入正确的容器编号！"
    fi
    #根据用户输入的编号获取对应容器的变量名
    container_variable=$(echo "$containers" | awk "NR==$container_number")
    #删除用户选择的容器
    docker stop "$container_variable" && docker rm "$container_variable"
    echo "容器已清除"
}

## 清理未使用镜像
function prune_images(){
    echo "警告！这将删除所有没有至少一个容器关联的映像。"
    docker image prune -a
}
function docker_logs() {
    echo "请选择要删除的容器："
    containers=$(docker ps --format "{{.Names}}")

    digital=1
    for container in $containers; do
        echo "$digital:$container"
        ((digital++))
    done

    #读取用户输入的编号
    read -p "请输入容器编号:" container_number
    # 判断用户输入的数字是否有效
    if ! [[ "$container_number" =~ ^[1-9][0-9]*$ ]] || (( container_number < 1 || container_number > digital-1 )); then
        Output_Error "输入的编号无效，请输入正确的容器编号！"
    fi
    #根据用户输入的编号获取对应容器的变量名
    container_variable=$(echo "$containers" | awk "NR==$container_number")
    docker logs $container_variable
}
function Options() {
    echo "请选择一个选项："
    echo "1. 进入容器内部"
    echo "2. update容器"
    echo "3. 停止并删除容器"
    echo "4. 清理未使用镜像"
    echo "5. 查询docker日志"
    echo "6. 退出程序"
    read -p "请输入数字执行响应的功能[1-5]: " choice
    case $choice in
        1)
        exec_docker
        ;;
        2)
        update_docker
        ;;
        3)
        delete_docker
        ;;
        4)
        prune_images
        ;;
        5)
        docker_logs
        ;;
        6)
        exit 0
        ;;
        *)
        Output_Error "${red} 输入错误！退出程序 ${color_reset}"
        ;;

    esac

}

function main() {
    PermissionJudgment
    Options
}
main