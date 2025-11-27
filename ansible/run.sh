#!/usr/bin/env bash
set -eo pipefail

# ===== Color output =====
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { case $1 in
    info)  printf "%b %s\n" "${GREEN}[INFO]${NC}" "${*:2}" ;;
    warn)  printf "%b %s\n" "${YELLOW}[WARN]${NC}" "${*:2}" ;;
    error) printf "%b %s\n" "${RED}[ERROR]${NC}" "${*:2}" ;;
esac; }

# ===== Ensure script runs from its own directory =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ===== Install Ansible (Ubuntu only) =====
install_ansible() {
    if ! command -v ansible >/dev/null 2>&1; then
        log info "安装 Ansible..."
        sudo apt update
        sudo apt install -y ansible
    else
        log info "Ansible 已安装"
    fi
}

# ===== Check required Playbook files =====
check_files() {
    local required=("main.yml" "ansible.cfg" "inventory/hosts")
    for f in "${required[@]}"; do
        if [[ ! -f "$f" ]]; then
            log error "缺少必要文件: $f"
            exit 1
        fi
    done
}

# ===== Main =====
main() {
    log info "开始配置环境..."

    install_ansible
    check_files

    log info "执行 ansible-playbook main.yml"
    ansible-playbook main.yml

    log info "配置完成!"
}


# ===== 6. Cleanup handler =====
cleanup() {
    local code=$?
    [[ $code -ne 0 ]] && log error "脚本退出码: $code"
    exit $code
}
trap cleanup EXIT

main "$@"
