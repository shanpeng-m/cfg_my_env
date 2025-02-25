#!/usr/bin/env bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 检查是否提供了bag文件名
if [ "$#" -ne 1 ]; then
    echo -e "\033[0;31mUsage: $0 <bag_file>\033[0m"
    exit 1
fi

bag_file="$1"

# 检查文件是否存在
if [ ! -f "$bag_file" ]; then
    echo -e "${RED}Error: File '$bag_file' does not exist${NC}"
    exit 1
fi

# 检查文件读取权限
if [ ! -r "$bag_file" ]; then
    echo -e "${RED}Error: No read permission for '$bag_file'${NC}"
    exit 1
fi

# 检查ROS2环境
if ! command -v ros2 &> /dev/null; then
    echo -e "${RED}Error: ROS2 is not installed or not in PATH${NC}"
    exit 1
fi

# 判断文件名是否以 .db3 结尾
if [[ "$bag_file" == *.db3 ]]; then
    output_dir="$(cd "$(dirname "$bag_file")" && pwd)"  # 获取bag文件的绝对目录路径
else
    output_dir="$bag_file"  # 直接使用bag_file路径
fi

# 创建带时间戳的输出文件名
timestamp=$(date '+%Y%m%d_%H%M%S')
output_file="$output_dir/topic_list_${timestamp}.txt"  # 设置输出文件路径

# 提示用户开始加载 ROS 环境
echo -e "\033[0;34mLoading ROS environment...\033[0m"
source /opt/ros/humble/setup.zsh

# 提示用户重新索引 bag 文件
echo -e "\033[0;33mReindexing bag file...\033[0m"
ros2 bag reindex "$bag_file"

# 提示用户正在提取 topics
echo -e "\033[0;32mExtracting topics from bag file...\033[0m"
ros2 bag info "$bag_file" | awk '/Topic:/ && !/Topic information:/ {print $2}' > "$output_file"

# 输出完成信息
echo -e "\033[0;32mTopic names have been written to $output_file.\033[0m"

# 添加处理摘要
echo -e "${GREEN}Processing Summary:${NC}"
echo -e "${BLUE}Input bag: ${NC}$bag_file"
echo -e "${BLUE}Output file: ${NC}$output_file"
echo -e "${BLUE}Total topics: ${NC}$(wc -l < "$output_file")"

# 检查输出文件是否成功创建
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully completed!${NC}"
else
    echo -e "${RED}Error occurred during processing${NC}"
    exit 1
fi
