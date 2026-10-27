#!/bin/bash

# RimeBak TUI & Interaction Engine
# ============================================================================

# 隐藏/显示光标
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

# 清屏
clear_screen() { printf '\033[H\033[2J'; }

# 显示 Banner
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

# 增强型读取按键 (参考 Mole 项目实现)
read_key() {
    local key rest rest2
    IFS= read -r -s -n 1 key
    local read_status=$?
    [[ $read_status -ne 0 ]] && { echo "QUIT"; return 0; }
    
    # 空输入 = Enter
    [[ -z "$key" ]] && { echo "ENTER"; return 0; }
    
    case "$key" in
        $'\n'|$'\r') echo "ENTER" ;;
        ' ') echo "SPACE" ;;
        'q'|'Q') echo "QUIT" ;;
        'j'|'J') echo "DOWN" ;;
        'k'|'K') echo "UP" ;;
        'h'|'H') echo "BACK" ;;
        'l'|'L') echo "FORWARD" ;;
        '?') echo "HELP" ;;
        [1-9]) echo "NUM:$key" ;;
        $'\x1b')
            # ESC 序列处理 (支持 ESC [ 和 ESC O)
            if IFS= read -r -s -n 1 -t 1 rest 2>/dev/null; then
                if [[ "$rest" == "[" ]]; then
                    if IFS= read -r -s -n 1 -t 1 rest2 2>/dev/null; then
                        case "$rest2" in
                            "A") echo "UP" ;;
                            "B") echo "DOWN" ;;
                            "C") echo "FORWARD" ;;
                            "D") echo "BACK" ;;
                            *) echo "OTHER" ;;
                        esac
                    else
                        echo "BACK"  # ESC [ 后无输入视为 ESC
                    fi
                elif [[ "$rest" == "O" ]]; then
                    if IFS= read -r -s -n 1 -t 1 rest2 2>/dev/null; then
                        case "$rest2" in
                            "A") echo "UP" ;;
                            "B") echo "DOWN" ;;
                            "C") echo "FORWARD" ;;
                            "D") echo "BACK" ;;
                            *) echo "OTHER" ;;
                        esac
                    else
                        echo "OTHER"
                    fi
                else
                    echo "OTHER"
                fi
            else
                echo "BACK"  # 单独 ESC 键
            fi
            ;;
        *) echo "OTHER" ;;
    esac
}

# 清理残留输入缓冲区
drain_pending_input() {
    local drained=0
    while IFS= read -r -s -n 1 -t 0.01 _ 2>/dev/null; do
        ((drained++))
        [[ $drained -gt 100 ]] && break
    done
}


# 菜单项渲染
render_menu_option() {
    local idx="$1"
    local label="$2"
    local is_selected="$3"
    
    if [[ "$is_selected" == "true" ]]; then
        printf "  ${CYAN}▶${NC} ${BOLD}[%s] %s${NC}\n" "$idx" "$label"
    else
        printf "    [%s] %s\n" "$idx" "$label"
    fi
}

# 显示帮助
show_help_ui() {
    clear_screen
    show_banner
    printf "${BLUE}交互快捷键${NC}\n"
    printf "  ${GREEN}%-15s${NC} %s\n" "↑ / ↓ / j / k" "导航选择"
    printf "  ${GREEN}%-15s${NC} → / Enter / l" "确认进入"
    printf "  ${GREEN}%-15s${NC} ← / ESC / h" "返回上一级"
    printf "  ${GREEN}%-15s${NC} 1-9" "直接跳转"
    printf "  ${GREEN}%-15s${NC} q" "退出程序"
    printf "  ${GREEN}%-15s${NC} ?" "显示此帮助"
    echo
    read -n 1 -s -r -p "按任意键返回..."
}

# 关于页面 (PRD v3.3)
show_about_ui() {
    clear_screen
    show_banner
    printf "${BLUE}版本介绍 (v${VERSION})${NC}\n"
    printf "────────────────────────────────────────\n"
    printf "RimeBak 是一个专注于 Rime 输入法配置安全的专业工具。\n\n"
    printf "${CYAN}核心特性:${NC}\n"
    printf "  • 智能多源发现 (外置硬盘/iCloud/本地)\n"
    printf "  • Git 增量同步与云端镜像\n"
    printf "  • 自动环境诊断与冲突修复\n"
    printf "  • 极致清洁的 TUI 交互体验\n\n"
    printf "${GRAY}作者: 凌一 (Jascenn)${NC}\n"
    printf "${GRAY}GitHub: https://github.com/Jascenn${NC}\n"
    printf "────────────────────────────────────────\n"
    read -n 1 -s -r -p "按任意键返回..."
}

export -f hide_cursor show_cursor clear_screen show_banner read_key render_menu_option show_help_ui show_about_ui
