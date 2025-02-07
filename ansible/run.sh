#!/usr/bin/env bash
set -eo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认值
MODE=${1:-interactive}
TAGS=${2:-""}
EXTRA_VARS=""

# 打印带颜色的消息
log() {
    local level=$1
    shift
    case $level in
        "info") echo -e "${GREEN}[INFO]${NC} $*" ;;
        "warn") echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "error") echo -e "${RED}[ERROR]${NC} $*" ;;
    esac
}

# 检查系统类型
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# 安装依赖
install_dependencies() {
    local os_type=$(check_os)
    log "info" "检测到系统类型: $os_type"

    case $os_type in
        "macos")
            if ! command -v brew &> /dev/null; then
                log "info" "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            if ! command -v ansible &> /dev/null; then
                log "info" "通过 pip 安装 Ansible..."
                python3 -m pip install --user ansible
            fi
            ;;
        "debian")
            if ! command -v ansible &> /dev/null; then
                log "info" "通过 apt 安装 Ansible..."
                sudo apt update
                sudo apt install -y ansible
            fi
            ;;
        "redhat")
            if ! command -v ansible &> /dev/null; then
                log "info" "通过 dnf 安装 Ansible..."
                sudo dnf install -y ansible
            fi
            ;;
        *)
            log "error" "不支持的操作系统"
            exit 1
            ;;
    esac
}

# 检查必要文件
check_files() {
    local required_files=("main.yml" "ansible.cfg" "inventory/hosts")
    for file in "${required_files[@]}"; do
        if [[ ! -f $file ]]; then
            log "error" "缺少必要文件: $file"
            exit 1
        fi
    done
}

# 交互式配置
configure_installation() {
    local config=()
    
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "\n${GREEN}=== 配置安装选项 ===${NC}"
        
        read -p "安装开发工具 (git, vim, etc.)? [Y/n]: " dev_tools
        [[ $dev_tools =~ ^[Nn]$ ]] || config+=("dev")
        
        read -p "配置 ZSH 环境? [Y/n]: " zsh_config
        [[ $zsh_config =~ ^[Nn]$ ]] || config+=("zsh")
        
        read -p "安装 Docker 相关工具? [Y/n]: " docker_tools
        [[ $docker_tools =~ ^[Nn]$ ]] || config+=("docker")
        
        if [[ ${#config[@]} -gt 0 ]]; then
            TAGS=$(IFS=,; echo "${config[*]}")
        fi
    fi
}

# 主函数
main() {
    log "info" "开始配置环境..."
    
    # 检查依赖
    install_dependencies
    
    # 检查必要文件
    check_files
    
    # 配置安装选项
    configure_installation
    
    # 构建命令
    local cmd="ansible-playbook main.yml"
    [[ -n "$TAGS" ]] && cmd+=" --tags $TAGS"
    [[ -n "$EXTRA_VARS" ]] && cmd+=" --extra-vars '$EXTRA_VARS'"
    
    # 执行playbook
    log "info" "执行命令: $cmd"
    eval $cmd
    
    log "info" "配置完成!"
}

# 清理函数
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "error" "脚本执行失败，退出码: $exit_code"
    fi
    exit $exit_code
}

# 注册清理函数
trap cleanup EXIT

# 执行主函数
main "$@"