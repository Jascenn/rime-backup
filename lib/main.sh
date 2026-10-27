#!/bin/bash

# RimeBak Main Interface Module
# ============================================================================

# 启动动画
show_intro_animation() {
    [[ ! -t 1 ]] && return  # 非终端跳过
    
    clear_screen
    hide_cursor
    printf '\n'
    
    # Rime Logo 动画
    local -a logo_lines=(
        "   ____  _                ____        _    "
        "  |  _ \\(_)_ __ ___   ___| __ )  __ _| | __"
        "  | |_) | | '_ \` _ \\ / _ \\  _ \\ / _\` | |/ /"
        "  |  _ <| | | | | | |  __/ |_) | (_| |   < "
        "  |_| \\_\\_|_| |_| |_|\\___|____/ \\__,_|_|\\_\\"
    )
    
    for line in "${logo_lines[@]}"; do
        printf "${PURPLE}%s${NC}\n" "$line"
        sleep 0.08
    done
    
    printf "\n  ${GREEN}Rime 输入法配置备份工具${NC}  ${GRAY}v%s${NC}\n" "$VERSION"
    sleep 0.3
    
    show_cursor
}

# 渲染主菜单 (无闪烁)
render_main_menu() {
    local current="$1"
    local first_draw="${2:-false}"
    
    if [[ "$first_draw" == "true" ]]; then
        clear_screen
    else
        # 光标定位到顶部，避免闪烁
        printf '\033[H'
    fi
    
    # 清除每行后重绘
    printf '\r\033[2K\n'
    show_banner
    
    printf '\r\033[2K%b\n' "${BLUE}选择操作${NC}"
    printf '\r\033[2K%s\n' "────────────────────────────────────────"
    
    printf '\r\033[2K%b\n' "$(render_menu_option 1 "备份       (Backup)   创建新备份" "$([[ $current -eq 1 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 2 "恢复       (Restore)  恢复指定版本" "$([[ $current -eq 2 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 3 "列表       (List)     查看所有备份" "$([[ $current -eq 3 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 4 "清理       (Clean)    删除旧备份文件" "$([[ $current -eq 4 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 5 "同步       (Git)      云端 GitHub 同步" "$([[ $current -eq 5 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 6 "统计       (Stats)    查看存储占用" "$([[ $current -eq 6 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 7 "诊断       (Doctor)   自检修复冲突" "$([[ $current -eq 7 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 8 "设置       (Setup)    重新配置向导" "$([[ $current -eq 8 ]] && echo true || echo false)")"
    printf '\r\033[2K%b\n' "$(render_menu_option 9 "关于       (About)    版本介绍与说明" "$([[ $current -eq 9 ]] && echo true || echo false)")"
    
    printf '\r\033[2K\n'
    printf '\r\033[2K  %b\n' "${GRAY}↑↓/jk 移动 | Enter/→ 进入 | q 退出${NC}"
    printf '\r\033[2K\n'
    
    # 清除剩余行
    printf '\033[J'
}

# 主交互循环
main_interactive_loop() {
    local current=1
    local total_options=9
    local first_draw=true
    
    # 启动动画
    show_intro_animation
    sleep 0.2
    
    # 检查冲突 (P0 启动项)
    check_conflicts 2>/dev/null || log_warn "检测到旧系统残留，建议运行 [7] 诊断程序"

    # 设置清理函数
    cleanup_and_exit() {
        show_cursor
        clear_screen
        exit 0
    }
    trap cleanup_and_exit INT TERM

    hide_cursor
    
    while true; do
        render_main_menu $current "$first_draw"
        [[ "$first_draw" == "true" ]] && first_draw=false

        key=$(read_key)
        drain_pending_input

        case "$key" in
            UP) ((current > 1)) && ((current--)) || current=$total_options ;;
            DOWN) ((current < total_options)) && ((current++)) || current=1 ;;
            FORWARD|ENTER)
                show_cursor
                handle_menu_action $current
                hide_cursor
                first_draw=true
                ;;
            BACK) 
                # 主菜单忽略返回键
                ;;
            NUM:*)
                num=${key#NUM:}
                if [[ $num -le $total_options ]]; then 
                    current=$num
                    show_cursor
                    handle_menu_action $current
                    hide_cursor
                    first_draw=true
                fi
                ;;
            HELP) 
                show_cursor
                show_help_ui 
                hide_cursor
                first_draw=true
                ;;
            QUIT) cleanup_and_exit ;;
        esac
    done
}

# 菜单动作处理
handle_menu_action() {
    local action=$1
    case $action in
        1) # 备份
            echo ""
            read -p "输入备份备注 (可选): " note
            do_backup "" "$note"
            sleep 1
            ;;
        2) # 恢复
            list_backups_ui
            read -p "输入恢复序号 (或 latest): " idx
            do_restore "$idx"
            sleep 1
            ;;
        3) # 列表
            list_backups_ui "true"
            echo ""
            printf "${GRAY}按 Enter 返回...${NC}"
            read -r
            ;;
        4) # 清理
            clean_backups
            ;;
        5) # Git 同步
            git_sync
            sleep 1
            ;;
        6) # 统计
            show_stats
            echo ""
            printf "${GRAY}按 Enter 返回...${NC}"
            read -r
            ;;
        7) run_doctor ;;
        8) run_setup ;;
        9) show_about_ui ;;
    esac
}

# 命令分发 (非交互模式)
dispatch_command() {
    local cmd="${1:-}"
    shift 2>/dev/null || true
    
    case "$cmd" in
        "")
            # 无参数，进入交互模式
            if [[ ! -f "$CONFIG_FILE" ]]; then
                run_setup
            fi
            main_interactive_loop
            ;;
        list)
            list_backups_ui "${1:-false}"
            ;;
        restore)
            do_restore "${1:-latest}"
            ;;
        git)
            local sub="${1:-status}"
            case "$sub" in
                init) git_init ;;
                remote) git_remote "${2:-}" ;;
                sync) git_sync ;;
                status) git_status_ui ;;
                *) log_error "未知子命令: git $sub" ;;
            esac
            ;;
        setup) run_setup ;;
        doctor) run_doctor ;;
        about) show_about_ui ;;
        stats) show_stats ;;
        backup)
            do_backup "${1:-}" "${2:-}"
            ;;
        *)
            log_error "未知命令: $cmd"
            echo ""
            printf "创建自定义名称备份请使用: ${GREEN}rimebak backup <名称>${NC}\n"
            printf "查看全部命令请运行: ${GREEN}rimebak --help${NC}\n"
            return 2
            ;;
    esac
}

export -f main_interactive_loop handle_menu_action dispatch_command
