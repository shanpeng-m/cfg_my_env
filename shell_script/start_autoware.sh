#!/usr/bin/env bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 搜索路径列表（可包含多个路径）
SEARCH_PATHS=("$HOME/pilot-auto.x2" "$HOME/another-path")  # 实际搜索的路径列表
ADDITIONAL_PATHS=("$HOME/autoware" "/opt/autoware")        # 仅作为启动选项，不实际搜索

# 检查是否安装fzf
if command -v fzf &> /dev/null; then
    USE_FZF=true
else
    USE_FZF=false
fi

# 函数：显示目录列表并供用户选择
choose_directory() {
    echo -e "${YELLOW}正在搜索Autoware路径，请稍候...${NC}"
    local directories=()

    # 添加搜索路径下的子目录
    for search_path in "${SEARCH_PATHS[@]}"; do
        if [[ -d "$search_path" ]]; then
            for dir in "$search_path"/*/; do
                [[ -d "$dir" && -n "$dir" ]] && directories+=("$dir")
            done
        fi
    done

    # 添加其他指定路径（非搜索路径）到目录列表
    for path in "${ADDITIONAL_PATHS[@]}"; do
        [[ -d "$path" && -n "$path" ]] && directories+=("$path")
    done

    # 检查是否找到任何目录
    if [[ ${#directories[@]} -eq 0 ]]; then
        echo -e "${RED}未找到任何Autoware文件夹。${NC}"
        exit 1
    fi

    # 使用 fzf 或编号选择模式
    if [[ "$USE_FZF" = true ]]; then
        selected_directory=$(printf "%s\n" "${directories[@]}" | fzf --prompt="请选择Autoware文件夹: ")
    else
        echo -e "${BLUE}找到以下Autoware文件夹：${NC}"
        for i in "${!directories[@]}"; do
            echo -e "${GREEN}$((i+1)). ${directories[$i]}${NC}"
        done

        echo -e "${YELLOW}请输入要启动的Autoware文件夹编号：${NC}"
        read -r choice

        if [[ "$choice" -ge 1 && "$choice" -le "${#directories[@]}" ]]; then
            selected_directory="${directories[$((choice-1))]}"
        else
            echo -e "${RED}无效的选择。${NC}"
            exit 1
        fi
    fi

    if [[ -n "$selected_directory" ]]; then
        echo -e "${GREEN}选择的Autoware目录是：${selected_directory}${NC}"
        cd "$selected_directory" || exit 1

        # 检查 src 目录
        if [[ ! -d "src" ]]; then
            echo -e "${YELLOW}该目录尚未导入代码。是否导入？[Y/n]${NC}"
            read -r import_code
            import_code=${import_code:-Y}
            
            if [[ "$import_code" =~ ^[Yy]$ ]]; then
                mkdir -p src
                echo -e "${BLUE}导入autoware.repos...${NC}"
                vcs import src < autoware.repos
            else
                echo -e "${RED}已取消导入。${NC}"
                exit 1
            fi
        fi

        # 询问是否导入 tools.repos
        echo -e "${YELLOW}是否导入tools.repos？[Y/n]${NC}"
        read -r import_tools
        import_tools=${import_tools:-Y}

        if [[ "$import_tools" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}导入tools.repos...${NC}"
            vcs import src < tools.repos
        else
            echo -e "${RED}已跳过导入tools.repos。${NC}"
        fi

        # 询问是否导入 simulator.repos
        echo -e "${YELLOW}是否导入simulator.repos？[Y/n]${NC}"
        read -r import_simulator
        import_simulator=${import_simulator:-Y}

        if [[ "$import_simulator" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}导入simulator.repos...${NC}"
            vcs import src < simulator.repos
        else
            echo -e "${RED}已跳过导入simulator.repos。${NC}"
        fi

    else
        echo -e "${RED}选择已取消。${NC}"
        exit 1
    fi
}

# 运行选择目录函数
choose_directory
