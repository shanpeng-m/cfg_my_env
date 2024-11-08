#!/usr/bin/env bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 检查是否提供了rosbag文件名或目录
if [ "$#" -lt 1 ]; then
    echo -e "${RED}Usage: $0 <rosbag_file_or_directory> [--exclude-from-prefix <prefix1> <prefix2> ...] [--include <topic1> <topic2> ...] [additional ros2 bag play options]${NC}"
    exit 1
fi

# 初始化变量
rosbag_file="$1"
shift  # 移除第一个参数，剩余参数继续解析
exclude_prefixes=()
include_topics=()
additional_args=()

# 解析其余参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --exclude-from-prefix)
            shift  # 跳过此参数
            while [[ "$#" -gt 0 && "$1" != -* ]]; do
                exclude_prefixes+=("$1")  # 添加每个前缀到数组中
                shift
            done
            ;;
        --include)
            shift  # 跳过此参数
            while [[ "$#" -gt 0 && "$1" != -* ]]; do
                include_topics+=("$1")  # 添加每个话题到 include_topics 数组
                shift
            done
            ;;
        *)
            additional_args+=("$1")  # 将其他参数添加到 additional_args 数组
            shift
            ;;
    esac
done

# 显示解析出的排除前缀和包括话题
echo -e "${BLUE}Excluding topics with prefixes:${NC} ${exclude_prefixes[*]}"
echo -e "${BLUE}Including specific topics back:${NC} ${include_topics[*]}"

# 生成 topic_list.txt 文件
echo -e "${BLUE}Generating topic list...${NC}"
./filter_topic_info_from_ros2_bag_info.sh "$rosbag_file" || { echo -e "${RED}Failed to generate topic list.${NC}"; exit 1; }

# 检查 topic_list.txt 是否生成成功
topic_list_file="$(dirname "$rosbag_file")/topic_list.txt"
if [ ! -f "$topic_list_file" ]; then
    echo -e "${RED}Error: topic_list.txt not found. Please check filter_topic_info_from_ros2_bag_info.sh.${NC}"
    exit 1
fi

# 读取 topic_list.txt 并生成单个 --remap 参数，仅对包含指定前缀的 topic 执行重映射
remap_args="--remap"
while IFS= read -r topic; do
    exclude_topic=false

    # 检查 topic 是否包含任意一个排除的前缀
    for prefix in "${exclude_prefixes[@]}"; do
        if [[ "$topic" == "$prefix"* ]]; then
            exclude_topic=true
            break
        fi
    done

    # 如果该话题在包括列表中，不进行排除
    for include_topic in "${include_topics[@]}"; do
        if [[ "$topic" == "$include_topic" ]]; then
            exclude_topic=false
            echo -e "${GREEN}Including topic:${NC} $topic"
            break
        fi
    done

    # 如果话题被标记为排除，则生成重映射参数
    if $exclude_topic; then
        echo -e "${YELLOW}Excluding topic:${NC} $topic"
        remap_args+=" ${topic}:=/unused_topic"
    fi
done < "$topic_list_file"

# 输出最终的 remap_args 内容，供调试确认
echo -e "${BLUE}Generated remap arguments:${NC} ${remap_args}"

# 提示即将执行的命令
echo -e "${GREEN}Ready to execute the following command:${NC}"
echo -e "${YELLOW}ros2 bag play $rosbag_file ${remap_args} ${additional_args[*]}${NC}"

# 用户确认
read -p "Do you want to proceed? [Y/n]: " confirm
if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Executing...${NC}"
    ros2 bag play "$rosbag_file" ${remap_args} "${additional_args[@]}"
else
    echo -e "${RED}Command execution cancelled.${NC}"
    exit 0
fi
