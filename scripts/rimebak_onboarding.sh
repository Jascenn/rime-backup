#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
RUN_FROM_REPO=true

# 输出辅助
info() { printf '%s\n' "$1"; }
hr() { printf '%s\n' "----------------------------------------"; }

# 读取交互输入，默认值为 $2 (y/n)
ask_yes_no() {
    local prompt=$1
    local default=${2:-n}
    local answer
    if [ "$default" = "y" ]; then
        prompt+=" [Y/n] "
    else
        prompt+=" [y/N] "
    fi
    read -r -p "$prompt" answer || answer=""
    answer=${answer:-$default}
    case "${answer,,}" in
        y|yes) return 0 ;;
        *)     return 1 ;;
    esac
}

# 检查依赖
check_dependency() {
    local cmd=$1
    local install_hint=$2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        info "⚠️  未找到依赖：$cmd"
        info "    $install_hint"
        return 1
    fi
    info "✅  已找到：$cmd"
    return 0
}

hr
info "RimeBak 新手引导"
hr

info "项目路径：$PROJECT_ROOT"
cd "$PROJECT_ROOT"

# 1. 基础依赖
info "\n🔍 检查基础依赖"
check_dependency bash "请安装 Git Bash / Cygwin / WSL 等提供 Bash 的环境。"
check_dependency rsync "macOS 自带；Linux 可运行 'sudo apt install rsync'；Windows Git Bash/Cygwin 请在安装时添加。"

# 2. 确定命令入口
RUN_CMD="./rimebak.sh"
if command -v rimebak >/dev/null 2>&1; then
    RUN_CMD="rimebak"
    RUN_FROM_REPO=false
fi

if $RUN_FROM_REPO && ask_yes_no "是否要将脚本安装为全局命令（需要管理员权限）?" n; then
    info "\n🚀 运行安装脚本（可能需要输入密码）"
    bash "$PROJECT_ROOT/install.sh"
    if command -v rimebak >/dev/null 2>&1; then
        RUN_CMD="rimebak"
        RUN_FROM_REPO=false
        info "✅  安装完成，现在可以直接使用 'rimebak' 命令"
    else
        info "⚠️  未检测到全局命令，继续使用仓库内的 ./rimebak.sh"
    fi
fi

hr
info "后续命令将使用：$RUN_CMD"
hr

# 3. 运行 setup
if ask_yes_no "现在要运行初始配置 (setup) 吗?" y; then
    info "\n🛠  开始执行 $RUN_CMD setup"
    "$RUN_CMD" setup || info "⚠️  setup 过程中出现问题，可稍后手动运行"
fi

# 4. 立即创建首次备份
if ask_yes_no "是否立即创建第一份备份?" y; then
    info "\n💾  正在创建备份"
    "$RUN_CMD" || info "⚠️  备份失败，可稍后重试"
fi

# 5. 展示常用命令
hr
info "常用命令速查："
cat <<'TABLE'
  1. 查看备份      : rimebak list full
  2. 交互式清理    : rimebak clean        # 支持 1-3、latest、all 等输入
  3. 撤销清理      : rimebak undo         # 从 .rimebak_trash 恢复
  4. 打开备份      : rimebak open latest  # Finder/资源管理器
  5. 重新设置目录  : rimebak setup
TABLE

# 6. 排除规则提示
hr
info "📁 自定义排除规则"
info "可以编辑 ~/.config/rime_backup/excludes.txt，每行一个模式，例如："
info "  build/"
info "  .git/"
info "使用 !pattern 可撤销默认排除，例如 !build/"

# 7. 结束语
hr
info "✅ 引导完成，祝你使用愉快！"
if $RUN_FROM_REPO; then
    info "提示：你仍在仓库目录内，运行命令时需要写成 ./rimebak.sh"
fi

exit 0
