#!/bin/bash

# RimeBak Core Library
# ============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# 全局变量
DRY_RUN=${DRY_RUN:-false}
DEBUG=${DEBUG:-false}
INTERACTIVE=${INTERACTIVE:-false}
VERSION="3.0.0"

# 配置文件路径
CONFIG_DIR="$HOME/.config/rime_backup"
CONFIG_FILE="$CONFIG_DIR/config.sh"
EXCLUDE_FILE="$CONFIG_DIR/excludes.txt"
DEFAULT_EXCLUDES=("*.sh" ".git/" "build/")
EXCLUDE_PATTERNS=()
BACKUP_IN_PROGRESS=0

# ============================================================================
# 日志引擎
# ============================================================================

log_info() {
    local msg="$1"
    local path="${2:-}"
    if [[ -n "$path" ]]; then
        printf "${CYAN}[rimebak]${NC} %s ${GRAY}(%s)${NC}\n" "$msg" "$path"
    else
        printf "${CYAN}[rimebak]${NC} %s\n" "$msg"
    fi
}

log_success() {
    printf "${GREEN}[rimebak]${NC} ✓ %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[rimebak]${NC} ⚠ %s\n" "$1"
}

log_error() {
    printf "${RED}[rimebak]${NC} ✗ %s\n" "$1" >&2
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "${GRAY}[debug]${NC} %s\n" "$1"
    fi
}

# ============================================================================
# 配置加载
# ============================================================================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

export -f log_info log_success log_warn log_error log_debug
