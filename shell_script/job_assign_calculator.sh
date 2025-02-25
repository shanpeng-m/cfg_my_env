#!/usr/bin/env bash

# 检测当前shell类型
CURRENT_SHELL="bash"
if [ -n "$ZSH_VERSION" ]; then
    CURRENT_SHELL="zsh"
elif [ -n "$BASH_VERSION" ]; then
    CURRENT_SHELL="bash"
else
    echo "警告：未能识别的shell类型，默认使用bash语法"
fi

# 检查是否安装了bc
if ! command -v bc &> /dev/null; then
    echo "错误：需要安装 bc 命令来进行计算"
    echo "请使用包管理器安装，例如："
    echo "Ubuntu/Debian: sudo apt-get install bc"
    echo "CentOS/RHEL: sudo yum install bc"
    exit 1
fi

# 浮点数计算函数
calc() {
    echo "scale=2; $1" | bc
}

# 四舍五入到整数
round() {
    printf "%.0f" $(calc "$1")
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 打印使用说明
echo -e "${BLUE}使用说明：${NC}"
echo "请按照以下格式输入作业信息："
echo -e "${GREEN}作业名称${NC}（回车）"
echo -e "${GREEN}工时${NC}（格式：小时:分钟，例如 99:11）"
echo "重复输入多个作业信息"
echo -e "输入完成后，按${YELLOW}两次回车${NC}结束输入\n"

# 根据shell类型声明数组
if [ "$CURRENT_SHELL" = "zsh" ]; then
    typeset -a jobs
    typeset -a minutes
else
    declare -a jobs
    declare -a minutes
fi

total_minutes=0
job_count=0

# 临时存储当前的作业名称
current_job=""

# 读取输入直到遇到空行
while IFS= read -r line; do
    # 如果是空行则退出循环
    [[ -z "$line" ]] && break
    
    # 如果当前没有存储作业名称
    if [[ -z "$current_job" ]]; then
        current_job="$line"
    else
        # 检查时间格式是否正确
        if [[ ! "$line" =~ ^[0-9]+:[0-9]+$ ]]; then
            echo -e "${RED}错误：时间格式不正确（应为 小时:分钟）: $line${NC}"
            exit 1
        fi
        
        # 处理时间
        hours=$(echo "$line" | cut -d: -f1)
        mins=$(echo "$line" | cut -d: -f2)
        current_minutes=$((hours * 60 + mins))
        
        # 根据shell类型使用不同的数组添加方式
        if [ "$CURRENT_SHELL" = "zsh" ]; then
            jobs+=("$current_job")
            minutes+=($current_minutes)
        else
            jobs[job_count]="$current_job"
            minutes[job_count]=$current_minutes
        fi
        
        ((total_minutes += current_minutes))
        
        # 重置作业名称并增加计数
        current_job=""
        ((job_count++))
    fi
done

# 检查是否有输入数据
if [ $job_count -eq 0 ]; then
    echo -e "${RED}错误：没有输入数据${NC}"
    exit 1
fi

# 计算最大公约数函数
gcd() {
    local a=$1
    local b=$2
    while (( b != 0 )); do
        local temp=$b
        b=$((a % b))
        a=$temp
    done
    echo $a
}

# 输出结果
echo -e "\n${YELLOW}结果统计：${NC}"
echo "------------------------"


# 在显示百分比的部分修改为：
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        percentage=$(calc "scale=2; ${minutes[i]} * 100 / $total_minutes")
        hours=$((minutes[i] / 60))
        mins=$((minutes[i] % 60))
        echo -e "${GREEN}${jobs[i]}${NC}: ${hours}:${mins} (${BLUE}${percentage}%${NC})"
    done
else
    for ((i=0; i<job_count; i++)); do
        percentage=$(calc "scale=2; ${minutes[i]} * 100 / $total_minutes")
        hours=$((minutes[i] / 60))
        mins=$((minutes[i] % 60))
        echo -e "${GREEN}${jobs[i]}${NC}: ${hours}:${mins} (${BLUE}${percentage}%${NC})"
    done
fi

# 计算简化比例
echo -e "\n${YELLOW}简化比例：${NC}"
echo "------------------------"

# 根据shell类型获取第一个元素
if [ "$CURRENT_SHELL" = "zsh" ]; then
    current_gcd=${minutes[1]}
    start_idx=2
else
    current_gcd=${minutes[0]}
    start_idx=1
fi

# 找到所有分钟数的最大公约数
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=2; i<=job_count; i++)); do
        current_gcd=$(gcd $current_gcd ${minutes[i]})
    done
else
    for ((i=1; i<job_count; i++)); do
        current_gcd=$(gcd $current_gcd ${minutes[i]})
    done
fi

# 输出简化后的比例
ratio=""
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        simplified=$((minutes[i] / current_gcd))
        if [ $i -eq 1 ]; then
            ratio="$simplified"
        else
            ratio="${ratio}:${simplified}"
        fi
    done
else
    for ((i=0; i<job_count; i++)); do
        simplified=$((minutes[i] / current_gcd))
        if [ $i -eq 0 ]; then
            ratio="$simplified"
        else
            ratio="${ratio}:${simplified}"
        fi
    done
fi

echo -e "${BLUE}$ratio${NC}"

# 输出带作业名称的比例说明
echo -e "\n${YELLOW}比例对应关系：${NC}"
echo "------------------------"
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        simplified=$((minutes[i] / current_gcd))
        echo -e "${GREEN}${jobs[i]}${NC} => ${BLUE}$simplified${NC}"
    done
else
    for ((i=0; i<job_count; i++)); do
        simplified=$((minutes[i] / current_gcd))
        echo -e "${GREEN}${jobs[i]}${NC} => ${BLUE}$simplified${NC}"
    done
fi


# 修改转换为总和为10的比例部分
echo -e "\n${YELLOW}转换为总和为10的比例：${NC}"
echo "------------------------"

# 计算精确的比例并存储
declare -a exact_proportions
sum_rounded=0

# 首先计算精确值并存储
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        exact=$(calc "${minutes[i]} * 10 / $total_minutes")
        exact_proportions[$i]=$exact
    done
else
    for ((i=0; i<job_count; i++)); do
        exact=$(calc "${minutes[i]} * 10 / $total_minutes")
        exact_proportions[$i]=$exact
    done
fi

# 首先对所有值向下取整
declare -a rounded_values
total_rounded=0

if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        rounded_values[$i]=$(printf "%.0f" $(calc "scale=0; ${exact_proportions[$i]}/1"))
        total_rounded=$((total_rounded + rounded_values[$i]))
    done
else
    for ((i=0; i<job_count; i++)); do
        rounded_values[$i]=$(printf "%.0f" $(calc "scale=0; ${exact_proportions[$i]}/1"))
        total_rounded=$((total_rounded + rounded_values[$i]))
    done
fi

# 如果总和不等于10，调整最大值
if [ $total_rounded -ne 10 ]; then
    diff=$((10 - total_rounded))
    
    # 找出最大值的索引
    max_val=0
    max_idx=0
    if [ "$CURRENT_SHELL" = "zsh" ]; then
        for ((i=1; i<=job_count; i++)); do
            if (( $(calc "${exact_proportions[$i]} > $max_val") )); then
                max_val=${exact_proportions[$i]}
                max_idx=$i
            fi
        done
        # 调整最大值
        rounded_values[$max_idx]=$((rounded_values[$max_idx] + diff))
    else
        for ((i=0; i<job_count; i++)); do
            if (( $(calc "${exact_proportions[$i]} > $max_val") )); then
                max_val=${exact_proportions[$i]}
                max_idx=$i
            fi
        done
        # 调整最大值
        rounded_values[$max_idx]=$((rounded_values[$max_idx] + diff))
    fi
fi

# 输出结果
ratio_10=""
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        if [ $i -eq 1 ]; then
            ratio_10="${rounded_values[$i]}"
        else
            ratio_10="${ratio_10}:${rounded_values[$i]}"
        fi
    done
else
    for ((i=0; i<job_count; i++)); do
        if [ $i -eq 0 ]; then
            ratio_10="${rounded_values[$i]}"
        else
            ratio_10="${ratio_10}:${rounded_values[$i]}"
        fi
    done
fi

echo -e "${BLUE}$ratio_10${NC}"

# 输出带作业名称的10比例对应关系
echo -e "\n${YELLOW}总和为10的比例对应关系：${NC}"
echo "------------------------"
if [ "$CURRENT_SHELL" = "zsh" ]; then
    for ((i=1; i<=job_count; i++)); do
        echo -e "${GREEN}${jobs[i]}${NC} => ${BLUE}${rounded_values[$i]}${NC}"
    done
else
    for ((i=0; i<job_count; i++)); do
        echo -e "${GREEN}${jobs[i]}${NC} => ${BLUE}${rounded_values[$i]}${NC}"
    done
fi