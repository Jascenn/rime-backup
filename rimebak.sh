#!/bin/bash

# RimeBak - Rime Configuration Backup Tool
# ============================================================================
# Auther: 凌一 (Jascenn)
# Version: 3.0.0
# ============================================================================

set -euo pipefail

# 获取脚本所在目录，用于加载核心库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 智能库路径探测 (支持开发模式、Homebrew 安装模式和手动安装)
LIB_CANDIDATES=(
    "$SCRIPT_DIR/lib"
    "$SCRIPT_DIR/../libexec/rimebak"
    "$SCRIPT_DIR/../opt/rimebak/libexec/rimebak"
    "/opt/homebrew/opt/rimebak/libexec/rimebak"
    "/usr/local/opt/rimebak/libexec/rimebak"
    "/opt/homebrew/bin/rimebak_lib"
    "/usr/local/bin/rimebak_lib"
)

LIB_DIR=""
for candidate in "${LIB_CANDIDATES[@]}"; do
    if [[ -d "$candidate" ]]; then
        LIB_DIR="$candidate"
        break
    fi
done

if [[ -z "$LIB_DIR" ]]; then
    echo "Error: Cannot find rimebak library directory" >&2
    echo "Searched:" >&2
    printf '  %s\n' "${LIB_CANDIDATES[@]}" >&2
    exit 1
fi

# 1. 加载基础核心库
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
else
    echo "Error: Cannot find core library at $LIB_DIR/core.sh"
    exit 1
fi


# 2. 解析全局选项 (在加载其他库前完成，以便 DEBUG 生效)
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug) DEBUG=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help|-h) source "$LIB_DIR/tui.sh"; show_help_ui; exit 0 ;;
        --version|-v) source "$LIB_DIR/tui.sh"; show_banner; exit 0 ;;
        *) POSITIONAL_ARGS+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]+"${POSITIONAL_ARGS[@]}"}" # 恢复剩余参数 (兼容空数组)

# 3. 加载其余功能模块
source "$LIB_DIR/detect.sh"
source "$LIB_DIR/tui.sh"
source "$LIB_DIR/ops.sh"
source "$LIB_DIR/git_provider.sh"
source "$LIB_DIR/doctor.sh"
source "$LIB_DIR/setup.sh"

# 4. 初始化环境
load_config

# 5. 加载主界面模块并分发命令
source "$LIB_DIR/main.sh"
dispatch_command "${1:-}" "${2:-}" "${3:-}"
