#!/bin/bash

set -euo pipefail

# Auther: 凌一 (Jascenn)
# GitHub: https://github.com/Jascenn
# Email: darkerrouge@gmail.com
# Date：2025-06-09
# WeChat：Help000000

# Rime 备份工具
VERSION="2.0.0"

# ============================================================================
# 颜色定义 (参考 Mole 项目风格)
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# 全局选项
DRY_RUN=false
DEBUG=false
INTERACTIVE=false
# 自动判断不同设备的Rime设置文件夹
detect_rime_dir() {
    # 检测操作系统类型
    if [ "$(uname)" = "Darwin" ]; then
        # macOS
        echo "$HOME/Library/Rime"
    elif [ "$(uname)" = "Linux" ]; then
        # 检测Linux发行版和输入法前端
        if [ -d "$HOME/.config/ibus/rime" ]; then
            # iBus前端
            echo "$HOME/.config/ibus/rime"
        elif [ -d "$HOME/.config/fcitx/rime" ]; then
            # 老版本Fcitx前端
            echo "$HOME/.config/fcitx/rime"
        elif [ -d "$HOME/.local/share/fcitx5/rime" ]; then
            # Fcitx5前端
            echo "$HOME/.local/share/fcitx5/rime"
        else
            # 默认路径
            echo "$HOME/.config/rime"
        fi
    elif [[ "$(uname -s)" == *MINGW* ]] || [[ "$(uname -s)" == *CYGWIN* ]]; then
        # Windows (MSYS2, Cygwin, Git Bash等环境)
        if [ -d "$APPDATA/Rime" ]; then
            echo "$APPDATA/Rime"
        else
            # 如果找不到，返回一个可能的默认路径
            echo "$HOME/AppData/Roaming/Rime"
        fi
    else
        # 未知系统，使用默认路径
        echo "$HOME/.config/rime"
        echo "警告: 未能识别的操作系统，使用默认Rime路径" >&2
    fi
}

# 配置文件路径
CONFIG_DIR="$HOME/.config/rime_backup"
CONFIG_FILE="$CONFIG_DIR/config.sh"
EXCLUDE_FILE="$CONFIG_DIR/excludes.txt"
DEFAULT_EXCLUDES=("*.sh" ".git/" "build/")
EXCLUDE_PATTERNS=()
BACKUP_IN_PROGRESS=0
BACKUP_LIST=()
BACKUP_KEYS=()
BACKUP_TOTAL=0
TRASH_DIR=""
ROLLBACK_FILE=""

# ============================================================================
# 增强日志系统
# ============================================================================
log_info() {
    printf "${CYAN}[rimebak]${NC} %s\n" "$1"
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
# ASCII Art Banner
# ============================================================================
show_banner() {
    printf "${PURPLE}"
    cat <<'EOF'
   ____  _                ____        _    
  |  _ \(_)_ __ ___   ___| __ )  __ _| | __
  | |_) | | '_ ` _ \ / _ \  _ \ / _` | |/ /
  |  _ <| | | | | | |  __/ |_) | (_| |   < 
  |_| \_\_|_| |_| |_|\___|____/ \__,_|_|\_\
EOF
    printf "${NC}"
    printf "  ${GREEN}Rime 输入法配置备份工具${NC}  ${GRAY}v%s${NC}\n\n" "$VERSION"
}

# ============================================================================
# 帮助信息
# ============================================================================
show_help() {
    show_banner
    printf "${BLUE}命令${NC}\n"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak" "进入交互式菜单"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak <备份名称>" "创建带名称的备份"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak list [full]" "列出所有备份"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak restore <序号>" "恢复指定备份"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak clean" "交互式清理备份"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak undo" "撤销上次清理"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak open <序号>" "打开指定备份"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak stats" "查看备份统计"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak setup" "重新配置"
    echo
    printf "${BLUE}Git 同步${NC}\n"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak git init" "初始化 Git 仓库"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak git remote <url>" "设置远程仓库"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak git sync" "提交并推送"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak git pull" "从远程拉取"
    printf "  ${GREEN}%-28s${NC} %s\n" "rimebak git status" "查看 Git 状态"
    echo
    printf "${BLUE}选项${NC}\n"
    printf "  ${GREEN}%-28s${NC} %s\n" "--dry-run" "预览操作，不实际执行"
    printf "  ${GREEN}%-28s${NC} %s\n" "--debug" "显示调试信息"
    printf "  ${GREEN}%-28s${NC} %s\n" "--help, -h" "显示帮助"
    printf "  ${GREEN}%-28s${NC} %s\n" "--version, -v" "显示版本"
    echo
    printf "${BLUE}示例${NC}\n"
    printf "  ${GRAY}rimebak "升级前备份"${NC}        创建带描述的备份\n"
    printf "  ${GRAY}rimebak restore latest${NC}     恢复最新备份\n"
    printf "  ${GRAY}rimebak git sync${NC}           同步到 GitHub\n"
    echo
}

show_version() {
    printf "RimeBak v%s\n" "$VERSION"
    printf "系统: %s\n" "$(uname -s)"
    printf "架构: %s\n" "$(uname -m)"
}

# ============================================================================
# 交互式菜单
# ============================================================================
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

show_menu_option() {
    local num="$1"
    local text="$2"
    local selected="$3"
    if [[ "$selected" == "true" ]]; then
        printf "  ${CYAN}▶${NC} ${BOLD}[%s] %s${NC}" "$num" "$text"
    else
        printf "    [%s] %s" "$num" "$text"
    fi
}

read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null || return 1
    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key 2>/dev/null || true
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "OTHER" ;;
        esac
    elif [[ "$key" == "" ]]; then
        echo "ENTER"
    elif [[ "$key" =~ ^[1-6]$ ]]; then
        echo "NUM:$key"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo "QUIT"
    elif [[ "$key" == "h" || "$key" == "H" ]]; then
        echo "HELP"
    else
        echo "OTHER"
    fi
}

show_main_menu() {
    local selected="${1:-1}"
    
    printf '\033[H\033[2J'  # 清屏
    show_banner
    
    printf "${BLUE}选择操作${NC}\n\n"
    printf "%s\n" "$(show_menu_option 1 "备份     创建新备份" "$([[ $selected -eq 1 ]] && echo true || echo false)")"
    printf "%s\n" "$(show_menu_option 2 "列表     查看所有备份" "$([[ $selected -eq 2 ]] && echo true || echo false)")"
    printf "%s\n" "$(show_menu_option 3 "清理     删除旧备份" "$([[ $selected -eq 3 ]] && echo true || echo false)")"
    printf "%s\n" "$(show_menu_option 4 "恢复     撤销上次清理" "$([[ $selected -eq 4 ]] && echo true || echo false)")"
    printf "%s\n" "$(show_menu_option 5 "打开     在 Finder 中查看" "$([[ $selected -eq 5 ]] && echo true || echo false)")"
    printf "%s\n" "$(show_menu_option 6 "设置     重新配置" "$([[ $selected -eq 6 ]] && echo true || echo false)")"
    echo
    printf "  ${GRAY}↑↓ 选择  |  Enter/数字 确认  |  H 帮助  |  Q 退出${NC}\n"
}

interactive_menu() {
    # 检查是否为 TTY
    if [[ ! -t 0 || ! -t 1 ]]; then
        log_warn "非交互式环境，执行标准备份"
        do_backup
        return
    fi
    
    local current=1
    trap 'show_cursor; exit 0' INT TERM
    hide_cursor
    
    while true; do
        show_main_menu $current
        
        local key
        if ! key=$(read_key); then
            continue
        fi
        
        case "$key" in
            "UP") ((current > 1)) && ((current--)) ;;
            "DOWN") ((current < 6)) && ((current++)) ;;
            "ENTER")
                show_cursor
                printf '\033[H\033[2J'
                case $current in
                    1) do_backup ;;
                    2) list_backups "false" ;;
                    3) do_backup; clean_old_backups ;;
                    4) undo_cleanup ;;
                    5) 
                        gather_backups
                        if [[ $BACKUP_TOTAL -gt 0 ]]; then
                            open_backup_at_index "latest"
                        else
                            log_warn "暂无备份"
                        fi
                        ;;
                    6) setup_config ;;
                esac
                exit 0
                ;;
            "NUM:"*)
                local num=${key#NUM:}
                show_cursor
                printf '\033[H\033[2J'
                case $num in
                    1) do_backup ;;
                    2) list_backups "false" ;;
                    3) do_backup; clean_old_backups ;;
                    4) undo_cleanup ;;
                    5)
                        gather_backups
                        if [[ $BACKUP_TOTAL -gt 0 ]]; then
                            open_backup_at_index "latest"
                        else
                            log_warn "暂无备份"
                        fi
                        ;;
                    6) setup_config ;;
                esac
                exit 0
                ;;
            "QUIT")
                show_cursor
                printf '\033[H\033[2J'
                exit 0
                ;;
            "HELP")
                show_cursor
                printf '\033[H\033[2J'
                show_help
                exit 0
                ;;
        esac
    done
}

cleanup_on_failure() {
    if [ "${BACKUP_IN_PROGRESS:-0}" -eq 1 ] && [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
        rm -rf -- "$BACKUP_DIR"
        echo "已清理未完成的备份目录: $BACKUP_DIR" >&2
    fi
    BACKUP_IN_PROGRESS=0
}

load_exclude_patterns() {
    EXCLUDE_PATTERNS=("${DEFAULT_EXCLUDES[@]}")

    if [ -f "$EXCLUDE_FILE" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            line=$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
            case "$line" in
                ''|"#"*)
                    continue
                    ;;
                !*)
                    local remove_pattern=${line#!}
                    for idx in "${!EXCLUDE_PATTERNS[@]}"; do
                        if [ "${EXCLUDE_PATTERNS[$idx]}" = "$remove_pattern" ]; then
                            unset 'EXCLUDE_PATTERNS[$idx]'
                        fi
                    done
                    continue
                    ;;
            esac
            EXCLUDE_PATTERNS+=("$line")
        done < "$EXCLUDE_FILE"
    fi

    EXCLUDE_PATTERNS=("${EXCLUDE_PATTERNS[@]}")
}

# 设置配置
setup_config() {
    local default_source_dir=$(detect_rime_dir)
    local default_backup_dir="$HOME/Documents/Rime_auto_backup"
    
    echo "欢迎使用 Rime 备份工具首次设置！"
    echo "请设置 Rime 配置文件夹路径和备份存储位置。"
    echo ""
    
    # 显示操作系统类型
    if [ "$(uname)" = "Darwin" ]; then
        echo "当前系统: macOS"
        # 检测 macOS 版本
        macos_version=$(sw_vers -productVersion 2>/dev/null)
        [ -n "$macos_version" ] && echo "系统版本: $macos_version"
    elif [ "$(uname)" = "Linux" ]; then
        echo "当前系统: Linux"
        # 检测 Linux 发行版
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "发行版: $NAME $VERSION_ID"
        fi
        # 检测输入法前端
        if [ -d "$HOME/.config/ibus/rime" ]; then
            echo "输入法前端: iBus"
        elif [ -d "$HOME/.config/fcitx/rime" ]; then
            echo "输入法前端: Fcitx"
        elif [ -d "$HOME/.local/share/fcitx5/rime" ]; then
            echo "输入法前端: Fcitx5"
        fi
    elif [[ "$(uname -s)" == *MINGW* ]] || [[ "$(uname -s)" == *CYGWIN* ]]; then
        echo "当前系统: Windows"
        # 检测 Windows 版本
        if [ -n "$OS" ]; then
            echo "系统版本: $OS"
        fi
        # 检测环境
        if [[ "$(uname -s)" == *MINGW* ]]; then
            echo "运行环境: MSYS2/MinGW"
        elif [[ "$(uname -s)" == *CYGWIN* ]]; then
            echo "运行环境: Cygwin"
        fi
    else
        echo "当前系统: $(uname -s)"
    fi
    echo ""
    
    # 显示终端信息
    if [ -n "$BASH" ]; then
        echo "当前 Shell: Bash $(bash --version | head -n1 | cut -d' ' -f4)"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "当前 Shell: Zsh $ZSH_VERSION"
    else
        echo "当前 Shell: $(basename "$SHELL")"
    fi
    echo ""
    
    # 确认 Rime 配置目录
    echo "检测到的 Rime 配置目录: $default_source_dir"
    read -p "是否使用此目录? (y/n) [y]: " use_default_source
    use_default_source=${use_default_source:-y}
    
    if [ "$use_default_source" != "y" ] && [ "$use_default_source" != "Y" ]; then
        read -p "请输入 Rime 配置目录路径: " SOURCE_DIR
    else
        SOURCE_DIR="$default_source_dir"
    fi
    
    # 确认 iCloud 路径
    local icloud_dir="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    local icloud_backup="$icloud_dir/Rime-部分/Rime_auto_backup"
    
    if [ -d "$icloud_dir" ]; then
        echo "检测到 iCloud 云盘目录。"
        read -p "是否将备份保存到 iCloud? (y/n) [y]: " use_icloud
        use_icloud=${use_icloud:-y}
        
        if [ "$use_icloud" = "y" ] || [ "$use_icloud" = "Y" ]; then
            default_backup_dir="$icloud_backup"
            mkdir -p "$default_backup_dir"
        fi
    fi
    
    # 确认备份目录
    echo "默认备份目录: $default_backup_dir"
    read -p "是否使用此目录? (y/n) [y]: " use_default_backup
    use_default_backup=${use_default_backup:-y}
    
    if [ "$use_default_backup" != "y" ] && [ "$use_default_backup" != "Y" ]; then
        read -p "请输入备份目录路径: " BACKUP_BASE
        mkdir -p "$BACKUP_BASE"
    else
        BACKUP_BASE="$default_backup_dir"
        mkdir -p "$BACKUP_BASE"
    fi
    
    # 保存配置
    mkdir -p "$CONFIG_DIR"
    echo "# Rime 备份工具配置文件 - $(date)" > "$CONFIG_FILE"
    echo "SOURCE_DIR=\"$SOURCE_DIR\"" >> "$CONFIG_FILE"
    echo "BACKUP_BASE=\"$BACKUP_BASE\"" >> "$CONFIG_FILE"
    
    echo "配置已保存到 $CONFIG_FILE"
    
    # 询问是否设置全局命令
    setup_global_command
}

# 设置全局命令
setup_global_command() {
    echo ""
    read -p "是否设置为全局命令? (y/n) [y]: " setup_global
    setup_global=${setup_global:-y}
    
    if [ "$setup_global" = "y" ] || [ "$setup_global" = "Y" ]; then
        # 获取脚本的绝对路径
        SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
        
        # 确定用户使用的 shell
        if [ -n "$BASH" ]; then
            SHELL_RC="$HOME/.bashrc"
            [ -f "$HOME/.bash_profile" ] && SHELL_RC="$HOME/.bash_profile"
        elif [ -n "$ZSH_VERSION" ]; then
            SHELL_RC="$HOME/.zshrc"
        else
            # 默认使用 bash
            SHELL_RC="$HOME/.bashrc"
        fi
        
        read -p "设置命令名称 (默认: rimebak): " command_name
        command_name=${command_name:-rimebak}
        
        # 检查是否已经存在该别名
        if grep -q "alias $command_name=" "$SHELL_RC" 2>/dev/null; then
            echo "命令 '$command_name' 已存在于 $SHELL_RC 中。将更新它。"
            sed -i.bak "/alias $command_name=/d" "$SHELL_RC"
        fi
        
        # 添加别名到 shell 配置文件
        echo "\n# Rime 备份工具全局命令 - $(date)" >> "$SHELL_RC"
        echo "alias $command_name=\"$SCRIPT_PATH\"" >> "$SHELL_RC"
        
        echo "全局命令已设置完成！请重新加载终端配置或重启终端后使用。"
        echo "使用方法: $command_name [选项]"
    fi
}

# 检查配置文件是否存在，不存在则进行首次设置
if [ ! -f "$CONFIG_FILE" ]; then
    setup_config
    echo ""
    echo "首次设置完成！现在将执行标准备份..."
    echo ""
elif [ "${1:-}" = "setup" ]; then
    setup_config
    exit 0
fi

# 源目录和备份目录
source "$CONFIG_FILE"

# 如果配置文件中的目录不存在，重新使用自动检测的值
if [ ! -d "$SOURCE_DIR" ]; then
    echo "警告: 配置的 Rime 目录不存在，使用自动检测目录。"
    SOURCE_DIR=$(detect_rime_dir)
fi

# 检查备份目录是否存在，如果不存在则创建
if [ ! -d "$BACKUP_BASE" ]; then
    mkdir -p "$BACKUP_BASE"
    echo "创建备份目录: $BACKUP_BASE"
fi

load_exclude_patterns
if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
    log_info "排除规则: ${EXCLUDE_PATTERNS[*]}"
else
    log_info "未启用任何排除规则"
fi

TRASH_DIR="$BACKUP_BASE/.rimebak_trash"
ROLLBACK_FILE="$CONFIG_DIR/rollback_last.txt"

# 创建备份
DATE_TIME=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR=""

do_backup() {
    local backup_name="${1:-}"
    
    if [ -n "$backup_name" ]; then
        # 使用自定义名称创建备份目录
        backup_name="${backup_name// /_}" # 替换空格为下划线
        BACKUP_DIR="$BACKUP_BASE/Rime_${backup_name}_${DATE_TIME}"
    else
        # 使用默认名称创建备份目录
        BACKUP_DIR="$BACKUP_BASE/Rime_backup_${DATE_TIME}"
    fi

    mkdir -p "$BACKUP_DIR"

    log_info "创建备份目录: $BACKUP_DIR"
    log_info "开始同步: $SOURCE_DIR -> $BACKUP_DIR"

    BACKUP_IN_PROGRESS=1
    trap 'cleanup_on_failure' INT TERM ERR

    local -a rsync_args=(-av)
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        rsync_args+=("--exclude=$pattern")
    done

    log_info "执行 rsync..."
    rsync "${rsync_args[@]}" "$SOURCE_DIR/" "$BACKUP_DIR/"

    BACKUP_IN_PROGRESS=0
    trap - INT TERM ERR

    log_info "备份完成: $BACKUP_DIR"
}

gather_backups() {
    local -a entries=()

    log_info "扫描备份目录: $BACKUP_BASE"

    while IFS= read -r entry; do
        local name=${entry##*/}
        if [[ $name =~ ^Rime_(.+)_([0-9]{8})_([0-9]{6})$ ]]; then
            local key="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
            entries+=("$key"$'\t'"$entry")
        fi
    done < <(find "$BACKUP_BASE" -mindepth 1 -maxdepth 1 -type d -print)

    BACKUP_LIST=()
    BACKUP_KEYS=()
    BACKUP_TOTAL=0

    if [ ${#entries[@]} -gt 0 ]; then
        local sorted_entries
        sorted_entries=$(printf '%s\n' "${entries[@]}" | LC_ALL=C sort -r)
        while IFS=$'\t' read -r key path; do
            [ -z "$key" ] && continue
            BACKUP_KEYS+=("$key")
            BACKUP_LIST+=("$path")
        done <<<"$sorted_entries"
        BACKUP_TOTAL=${#BACKUP_LIST[@]}
    fi
}

print_backup_table() {
    local show_full_path="$1"

    echo "可用的 Rime 备份 (按时间从近到远排序):"
    echo "序号    创建时间            备份名称"
    echo "----------------------------------------------------"

    if [ "$BACKUP_TOTAL" -eq 0 ]; then
        echo "暂无备份"
        return 0
    fi

    local index=0
    for full_path in "${BACKUP_LIST[@]}"; do
        local backup_name=${full_path##*/}
        if [[ $backup_name =~ _([0-9]{8})_([0-9]{6})$ ]]; then
            local date_part=${BASH_REMATCH[1]}
            local time_part=${BASH_REMATCH[2]}
            local formatted_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}:${time_part:4:2}"
            local display_name="标准备份"

            if [[ $backup_name != Rime_backup_* ]]; then
                display_name=$(printf '%s' "$backup_name" | sed -E 's/^Rime_(.+)_[0-9]{8}_[0-9]{6}$/\1/' | tr '_' ' ')
            fi

            printf "%-8s %-19s %s\n" "[$((++index))]" "$formatted_date" "$display_name"

            if [ "$show_full_path" = "true" ]; then
                echo "    路径: $full_path"
            fi
        fi
    done
}

list_backups() {
    local show_full_path="$1"

    gather_backups

    log_info "共找到 $BACKUP_TOTAL 个备份"

    print_backup_table "$show_full_path"

    if [ "$BACKUP_TOTAL" -gt 0 ]; then
        echo ""
        echo "提示: 使用 './rimebak.sh open 序号' 可打开指定备份文件夹"
        if [ "$show_full_path" != "true" ]; then
            echo "提示: 使用 './rimebak.sh list full' 可查看备份完整路径"
        fi
    fi
}

clean_old_backups() {
    gather_backups

    if [ "$BACKUP_TOTAL" -le 1 ]; then
        echo "当前备份数量不超过 1，无需清理"
        return 0
    fi

    print_backup_table "false"
    echo ""
    log_info "输入要删除的备份序号（空格分隔，可使用 latest/oldest/-1 等关键字），直接回车取消"
    local selection
    if ! IFS= read -r selection; then
        echo "未收到输入，已取消清理"
        return 0
    fi

    if [ -z "$selection" ]; then
        echo "已取消清理"
        return 0
    fi

    local -a candidates=()
    for token in $selection; do
        if [[ "$token" =~ ^[Aa][Ll][Ll]$ ]]; then
            candidates=()
            local i
            for ((i = 1; i <= BACKUP_TOTAL; i++)); do
                candidates+=("$i")
            done
            break
        fi

        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start=${BASH_REMATCH[1]}
            local end=${BASH_REMATCH[2]}
            if [ "$start" -gt "$end" ]; then
                local tmp=$start
                start=$end
                end=$tmp
            fi
            local i
            for ((i = start; i <= end; i++)); do
                candidates+=("$i")
            done
            continue
        fi

        local idx
        if ! idx=$(resolve_backup_index "$token"); then
            echo "跳过无效输入: $token"
            continue
        fi

        candidates+=("$idx")
    done

    if [ ${#candidates[@]} -eq 0 ]; then
        echo "未选择有效备份，已取消清理"
        return 0
    fi

    local unique_indexes
    unique_indexes=$(printf '%s\n' "${candidates[@]}" | LC_ALL=C sort -n -u)

    local -a final_indexes=()
    while IFS= read -r idx_value; do
        [ -z "$idx_value" ] && continue
        if [ "$idx_value" -lt 1 ] || [ "$idx_value" -gt "$BACKUP_TOTAL" ]; then
            echo "跳过越界序号: $idx_value"
            continue
        fi
        final_indexes+=("$idx_value")
    done <<<"$unique_indexes"

    if [ ${#final_indexes[@]} -eq 0 ]; then
        echo "未选择有效备份，已取消清理"
        return 0
    fi

    echo "以下备份将被删除:"
    for idx in "${final_indexes[@]}"; do
        local path=${BACKUP_LIST[$((idx-1))]}
        echo "  [$idx] $path"
    done

    local confirm
    if ! read -r -p "确认删除? (y/N): " confirm; then
        echo "未收到输入，已取消清理"
        return 0
    fi
    confirm=${confirm:-n}
    confirm=$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        echo "已取消清理"
        return 0
    fi

    mkdir -p "$TRASH_DIR"
    : > "$ROLLBACK_FILE"

    local moved_any=0
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    for idx in "${final_indexes[@]}"; do
        local path=${BACKUP_LIST[$((idx-1))]}
        local base_name=${path##*/}
        local target="$TRASH_DIR/$base_name"

        while [ -e "$target" ]; do
            target="$TRASH_DIR/${base_name}_${timestamp}_$RANDOM"
        done

        if mv "$path" "$target"; then
            log_info "已移动备份 [$idx] 到临时回收站: $target"
            printf '%s|%s\n' "$target" "$path" >> "$ROLLBACK_FILE"
            moved_any=1
        else
            echo "移动失败，跳过: $path" >&2
        fi
    done

    if [ "$moved_any" -eq 1 ]; then
        log_info "清理完成，所有选中备份已移动到: $TRASH_DIR"
        log_info "如需恢复，可运行 './rimebak.sh undo'"
    else
        rm -f "$ROLLBACK_FILE"
        echo "未成功移动任何备份"
    fi
}

undo_cleanup() {
    if [ ! -f "$ROLLBACK_FILE" ] || ! grep -q '.' "$ROLLBACK_FILE" 2>/dev/null; then
        echo "没有可回滚的记录" >&2
        return 1
    fi

    log_info "开始回滚上一次清理"
    local restored=0
    local failed=0

    while IFS='|' read -r src dest; do
        [ -z "$src" ] && continue
        if [ ! -d "$src" ]; then
            echo "无法恢复: 临时目录不存在 -> $src" >&2
            failed=$((failed + 1))
            continue
        fi

        local target="$dest"
        if [ -d "$target" ]; then
            local base_name=${target##*/}
            target="$BACKUP_BASE/${base_name}_restore_$(date +%Y%m%d_%H%M%S)"
            echo "目标已存在，改为恢复到: $target" >&2
        fi

        if mv "$src" "$target"; then
            log_info "已恢复备份: $target"
            restored=$((restored + 1))
        else
            echo "恢复失败: $src" >&2
            failed=$((failed + 1))
        fi
    done < "$ROLLBACK_FILE"

    rm -f "$ROLLBACK_FILE"

    if [ "$restored" -gt 0 ]; then
        log_info "回滚完成，共恢复 $restored 个备份"
    fi

    if [ "$failed" -gt 0 ]; then
        echo "有 $failed 个备份未能恢复，请手动检查 $TRASH_DIR" >&2
        return 1
    fi

    return 0
}

resolve_backup_index() {
    local token="$1"

    if [ -z "$token" ] || [ "$token" = "latest" ]; then
        echo 1
        return 0
    fi

    if [ "$token" = "oldest" ]; then
        echo "$BACKUP_TOTAL"
        return 0
    fi

    if [[ $token =~ ^-[0-9]+$ ]]; then
        local offset=${token#-}
        if [ "$offset" -eq 0 ]; then
            echo "错误: 序号 0 无效。" >&2
            return 1
        fi
        local index=$((BACKUP_TOTAL - offset + 1))
        echo "$index"
        return 0
    fi

    if [[ $token =~ ^[0-9]+$ ]]; then
        echo "$token"
        return 0
    fi

    echo "错误: 不支持的序号或关键字 '$token'。可用: latest, oldest, 正整数, -正整数。" >&2
    return 1
}

open_backup_at_index() {
    local token="$1"

    gather_backups

    if [ "${BACKUP_TOTAL:-0}" -eq 0 ]; then
        echo "暂无可用备份" >&2
        return 1
    fi

    local target_index
    if ! target_index=$(resolve_backup_index "$token"); then
        return 1
    fi

    if ! [[ $target_index =~ ^[0-9]+$ ]] || [ "$target_index" -lt 1 ] || [ "$target_index" -gt "$BACKUP_TOTAL" ]; then
        echo "错误: 未找到序号 $target_index 对应的备份。请运行 './rimebak.sh list' 查看可用备份列表 (共 $BACKUP_TOTAL 个)。" >&2
        return 1
    fi

    local selected_path=${BACKUP_LIST[$((target_index-1))]}
    echo "打开备份文件夹: $selected_path"

    if command -v open >/dev/null 2>&1; then
        open "$selected_path" >/dev/null 2>&1 && return 0
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$selected_path" >/dev/null 2>&1 && return 0
    fi
    if command -v wslview >/dev/null 2>&1; then
        wslview "$selected_path" >/dev/null 2>&1 && return 0
    fi
    if [ -n "${WSL_INTEROP:-}" ] && command -v explorer.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
        explorer.exe "$(wslpath -w "$selected_path")" >/dev/null 2>&1 && return 0
    fi
    if [[ "$(uname -s)" == *MINGW* || "$(uname -s)" == *MSYS* || "$(uname -s)" == *CYGWIN* ]]; then
        local windows_path="$selected_path"
        if command -v cygpath >/dev/null 2>&1; then
            windows_path=$(cygpath -w "$selected_path")
        fi
        if command -v cmd.exe >/dev/null 2>&1; then
            cmd.exe /c start "" "$windows_path" >/dev/null 2>&1 && return 0
        fi
    fi

    echo "未找到可用于打开目录的命令，请手动访问该路径。"
    return 1
}

# ============================================================================
# 恢复备份
# ============================================================================
do_restore() {
    local target="${1:-latest}"
    
    gather_backups
    
    if [ "$BACKUP_TOTAL" -eq 0 ]; then
        log_error "暂无可用备份"
        return 1
    fi
    
    local target_index
    if ! target_index=$(resolve_backup_index "$target"); then
        return 1
    fi
    
    if ! [[ $target_index =~ ^[0-9]+$ ]] || [ "$target_index" -lt 1 ] || [ "$target_index" -gt "$BACKUP_TOTAL" ]; then
        log_error "未找到序号 $target_index 对应的备份"
        return 1
    fi
    
    local backup_path="${BACKUP_LIST[$((target_index-1))]}"
    local backup_name="${backup_path##*/}"
    
    log_info "准备恢复备份: $backup_name"
    log_info "源: $backup_path"
    log_info "目标: $SOURCE_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "[预览模式] 将执行以下操作:"
        log_info "  1. 创建当前配置的自动备份"
        log_info "  2. 将 $backup_name 恢复到 $SOURCE_DIR"
        log_warn "这是预览模式，未执行任何操作"
        return 0
    fi
    
    # 恢复前自动备份当前配置
    log_info "恢复前创建当前配置备份..."
    local old_date_time="$DATE_TIME"
    DATE_TIME=$(date +"%Y%m%d_%H%M%S")
    do_backup "恢复前自动备份"
    DATE_TIME="$old_date_time"
    
    # 执行恢复
    log_info "开始恢复..."
    rsync -av --delete "$backup_path/" "$SOURCE_DIR/"
    
    log_success "已成功恢复备份: $backup_name"
    log_info "请重新部署 Rime 以应用更改"
    
    return 0
}

# ============================================================================
# Git 同步功能
# ============================================================================
git_init() {
    if [ -d "$BACKUP_BASE/.git" ]; then
        log_warn "Git 仓库已存在"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[预览模式] 将在 $BACKUP_BASE 初始化 Git 仓库"
        return 0
    fi
    
    cd "$BACKUP_BASE" || return 1
    git init
    
    # 创建 .gitignore
    cat > .gitignore << 'EOF'
.rimebak_trash/
*.log
.DS_Store
EOF
    
    git add .
    git commit -m "Initial commit: RimeBak backup repository"
    
    log_success "Git 仓库初始化完成"
    log_info "现在可以使用 'rimebak git remote <url>' 设置远程仓库"
}

git_remote() {
    local url="$1"
    
    if [ ! -d "$BACKUP_BASE/.git" ]; then
        log_error "请先运行 'rimebak git init' 初始化仓库"
        return 1
    fi
    
    if [ -z "$url" ]; then
        log_error "请提供远程仓库 URL"
        log_info "用法: rimebak git remote <url>"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[预览模式] 将设置远程仓库: $url"
        return 0
    fi
    
    cd "$BACKUP_BASE" || return 1
    
    if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "$url"
        log_info "已更新远程仓库 URL"
    else
        git remote add origin "$url"
        log_info "已添加远程仓库"
    fi
    
    log_success "远程仓库设置完成: $url"
}

git_sync() {
    if [ ! -d "$BACKUP_BASE/.git" ]; then
        log_error "请先运行 'rimebak git init' 初始化仓库"
        return 1
    fi
    
    cd "$BACKUP_BASE" || return 1
    
    local changes=$(git status --porcelain)
    
    if [ -z "$changes" ]; then
        log_info "没有新的更改需要同步"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[预览模式] 将提交以下更改:"
        git status --short
        return 0
    fi
    
    local commit_msg="Backup: $(date '+%Y-%m-%d %H:%M:%S')"
    
    git add .
    git commit -m "$commit_msg"
    
    if git remote get-url origin >/dev/null 2>&1; then
        log_info "推送到远程仓库..."
        if git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
            log_success "已推送到远程仓库"
        else
            log_warn "推送失败，请检查远程仓库配置"
        fi
    else
        log_warn "未设置远程仓库，仅本地提交"
        log_info "使用 'rimebak git remote <url>' 设置远程仓库"
    fi
    
    log_success "Git 同步完成"
}

git_pull() {
    if [ ! -d "$BACKUP_BASE/.git" ]; then
        log_error "请先运行 'rimebak git init' 初始化仓库"
        return 1
    fi
    
    cd "$BACKUP_BASE" || return 1
    
    if ! git remote get-url origin >/dev/null 2>&1; then
        log_error "未设置远程仓库"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[预览模式] 将从远程仓库拉取"
        return 0
    fi
    
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
    log_success "已从远程仓库拉取"
}

git_status() {
    if [ ! -d "$BACKUP_BASE/.git" ]; then
        log_error "请先运行 'rimebak git init' 初始化仓库"
        return 1
    fi
    
    cd "$BACKUP_BASE" || return 1
    
    echo ""
    printf "${BLUE}Git 状态${NC}\n"
    echo "----------------------------------------"
    
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "未设置")
    printf "远程仓库: %s\n" "$remote_url"
    
    local branch=$(git branch --show-current 2>/dev/null || echo "无")
    printf "当前分支: %s\n" "$branch"
    
    local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "无提交")
    printf "最新提交: %s\n" "$last_commit"
    
    echo ""
    git status --short
}

do_git() {
    local subcmd="${1:-}"
    shift 2>/dev/null || true
    
    case "$subcmd" in
        init)
            git_init
            ;;
        remote)
            git_remote "${1:-}"
            ;;
        sync)
            git_sync
            ;;
        pull)
            git_pull
            ;;
        status|"")
            git_status
            ;;
        *)
            log_error "未知 git 子命令: $subcmd"
            echo ""
            printf "${BLUE}可用命令${NC}\n"
            printf "  ${GREEN}rimebak git init${NC}          初始化 Git 仓库\n"
            printf "  ${GREEN}rimebak git remote <url>${NC}  设置远程仓库\n"
            printf "  ${GREEN}rimebak git sync${NC}          提交并推送\n"
            printf "  ${GREEN}rimebak git pull${NC}          从远程拉取\n"
            printf "  ${GREEN}rimebak git status${NC}        查看状态\n"
            return 1
            ;;
    esac
}

# ============================================================================
# 备份统计
# ============================================================================
show_stats() {
    gather_backups
    
    echo ""
    show_banner
    printf "${BLUE}备份统计${NC}\n"
    echo "========================================"
    
    printf "备份总数:   ${GREEN}%d${NC} 个\n" "$BACKUP_TOTAL"
    
    if [ "$BACKUP_TOTAL" -eq 0 ]; then
        echo "暂无备份数据"
        return 0
    fi
    
    # 最新和最早备份
    local latest="${BACKUP_LIST[0]}"
    local oldest="${BACKUP_LIST[$((BACKUP_TOTAL-1))]}"
    
    local latest_name="${latest##*/}"
    local oldest_name="${oldest##*/}"
    
    if [[ $latest_name =~ _([0-9]{8})_([0-9]{6})$ ]]; then
        local date_str="${BASH_REMATCH[1]}"
        printf "最新备份:   %s-%s-%s\n" "${date_str:0:4}" "${date_str:4:2}" "${date_str:6:2}"
    fi
    
    if [[ $oldest_name =~ _([0-9]{8})_([0-9]{6})$ ]]; then
        local date_str="${BASH_REMATCH[1]}"
        printf "最早备份:   %s-%s-%s\n" "${date_str:0:4}" "${date_str:4:2}" "${date_str:6:2}"
    fi
    
    # 计算总大小
    local total_size=$(du -sh "$BACKUP_BASE" 2>/dev/null | cut -f1)
    printf "总大小:     ${YELLOW}%s${NC}\n" "$total_size"
    
    # Git 状态
    if [ -d "$BACKUP_BASE/.git" ]; then
        printf "Git 状态:   ${GREEN}已启用${NC}\n"
        local remote_url=$(cd "$BACKUP_BASE" && git remote get-url origin 2>/dev/null || echo "")
        if [ -n "$remote_url" ]; then
            printf "远程仓库:   %s\n" "$remote_url"
        fi
    else
        printf "Git 状态:   ${GRAY}未启用${NC}\n"
    fi
    
    echo "========================================"
}

# ============================================================================
# 命令行解析
# ============================================================================

# 解析全局选项
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

command="${1:-}"
if [ $# -gt 0 ]; then
    shift
fi

log_debug "命令: $command"
log_debug "DRY_RUN: $DRY_RUN"
log_debug "DEBUG: $DEBUG"

case "$command" in
    "")
        # 无参数时进入交互菜单
        interactive_menu
        ;;
    list)
        show_full="false"
        if [ "${1:-}" = "full" ]; then
            show_full="true"
        fi
        list_backups "$show_full"
        exit 0
        ;;
    restore)
        do_restore "${1:-latest}"
        exit 0
        ;;
    clean)
        if [[ "$DRY_RUN" == "true" ]]; then
            gather_backups
            log_info "[预览模式] 当前共有 $BACKUP_TOTAL 个备份"
            print_backup_table "false"
            log_warn "这是预览模式，未执行任何操作"
            exit 0
        fi
        do_backup
        clean_old_backups
        exit 0
        ;;
    undo)
        if undo_cleanup; then
            exit 0
        else
            exit 1
        fi
        ;;
    open)
        if ! open_backup_at_index "${1:-}"; then
            exit 1
        fi
        exit 0
        ;;
    git)
        do_git "$@"
        exit 0
        ;;
    stats)
        show_stats
        exit 0
        ;;
    *)
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[预览模式] 将创建备份: Rime_${command// /_}_$DATE_TIME"
            log_info "源目录: $SOURCE_DIR"
            log_info "目标目录: $BACKUP_BASE"
            log_warn "这是预览模式，未执行任何操作"
            exit 0
        fi
        do_backup "$command"
        log_success "已创建带自定义名称的备份: $command"
        ;;
esac

echo ""
printf "${GRAY}提示：运行 'rimebak --help' 查看所有命令${NC}\n"

