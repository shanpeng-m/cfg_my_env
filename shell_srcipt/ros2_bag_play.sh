#!/usr/bin/env bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 检查是否提供了rosbag文件名或目录
if [ "$#" -lt 1 ]; then
    echo -e "${RED}Usage: $0 <rosbag_file_or_directory> [--exclude-from-prefix <prefix>] [additional ros2 bag play options]${NC}"
    exit 1
fi

# 初始化变量
rosbag_file="$1"
shift  # 移除第一个参数，剩余参数继续解析
exclude_prefix=""
additional_args=()

# 解析其余参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --exclude-from-prefix)
            exclude_prefix="$2"
            shift 2  # 跳过此参数及其后缀
            ;;
        *)
            additional_args+=("$1")  # 将其他参数添加到additional_args数组
            shift
            ;;
    esac
done

# 生成 topic_list.txt 文件
echo -e "${BLUE}Generating topic list...${NC}"
./filter_topic_info_from_ros2_bag_info.sh "$rosbag_file" || { echo -e "${RED}Failed to generate topic list.${NC}"; exit 1; }

# 检查 topic_list.txt 是否生成成功
topic_list_file="$(dirname "$rosbag_file")/topic_list.txt"
if [ ! -f "$topic_list_file" ]; then
    echo -e "${RED}Error: topic_list.txt not found. Please check filter_topic_info_from_ros2_bag_info.sh.${NC}"
    exit 1
fi

# 读取 topic_list.txt 并生成 --remap 参数
remap_args=""
while IFS= read -r topic; do
    # 如果 topic 以指定的前缀开头，生成 remap 参数
    if [[ "$topic" == "$exclude_prefix"* ]]; then
        remap_args+=" --remap ${topic}:=/unused_topic"
    fi
done < "$topic_list_file"

# 提示即将执行的命令
echo -e "${GREEN}Ready to execute the following command:${NC}"
echo -e "${YELLOW}ros2 bag play $rosbag_file $remap_args ${additional_args[*]}${NC}"

# 用户确认
read -p "Do you want to proceed? [Y/n]: " confirm
if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Executing...${NC}"
    ros2 bag play "$rosbag_file" $remap_args "${additional_args[@]}"
else
    echo -e "${RED}Command execution cancelled.${NC}"
    exit 0
fi
