#!/bin/bash

# RimeBak Setup Wizard Module
# ============================================================================

run_setup() {
    clear_screen
    show_banner
    printf "${BLUE}配置向导${NC}\n"
    printf "────────────────────────────────────────\n"
    
    # 1. 检测 Rime 目录
    local default_source=$(detect_rime_dir)
    printf "Rime 配置目录探测中...\n"
    printf "检测到: ${CYAN}%s${NC}\n" "$default_source"
    read -p "使用此目录? (Y/n): " confirm_source
    if [[ ! "$confirm_source" =~ ^[nN]$ ]]; then
        SOURCE_DIR="$default_source"
    else
        read -p "请输入自定义 Rime 目录: " SOURCE_DIR
    fi
    echo ""

    # 2. 检测备份位置 (智能发现)
    printf "正在智能搜索周边备份源 (P0-P3)...\n"
    smart_discover_backups
    
    if [[ ${#DISCOVERED_PATHS[@]:-0} -gt 0 ]]; then
        printf "${GREEN}✓ 发现以下备份位置:${NC}\n"
        local i=1
        for name in "${DISCOVERED_NAMES[@]+"${DISCOVERED_NAMES[@]}"}"; do
            printf "  [%d] %s\n" "$i" "$name"
            ((i++))
        done
        printf "  [%d] 自定义新位置\n" "$i"
        
        printf "\n推荐选择: ${CYAN}%s${NC}\n" "${DISCOVERED_NAMES[0]}"
        read -p "请选择 (默认 1): " choice
        choice=${choice:-1}
        
        if [[ "$choice" -eq "$i" ]]; then
            read -p "请输入备份存储绝对路径: " BACKUP_BASE
        else
            BACKUP_BASE="${DISCOVERED_PATHS[$((choice-1))]}"
        fi
    else
        printf "${YELLOW}! 未发现现有备份。${NC}\n"
        printf "请选择创建位置:\n"
        printf "  [1] 本地文档 (Documents/Rime_auto_backup)\n"
        printf "  [2] iCloud 云盘 (仅限 macOS)\n"
        printf "  [3] 自定义路径\n"
        read -p "选择: " choice
        case "$choice" in
            2) BACKUP_BASE="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Rime_auto_backup" ;;
            3) read -p "路径: " BACKUP_BASE ;;
            *) BACKUP_BASE="$HOME/Documents/Rime_auto_backup" ;;
        esac
    fi

    # 3. 保存配置
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BACKUP_BASE" 2>/dev/null
    
    cat > "$CONFIG_FILE" << EOF
# RimeBak Config generated on $(date)
SOURCE_DIR="$SOURCE_DIR"
BACKUP_BASE="$BACKUP_BASE"
EOF

    log_success "配置已成功保存至 $CONFIG_FILE"
    printf "  • 源: $SOURCE_DIR\n"
    printf "  • 目标: $BACKUP_BASE\n"
    echo ""
    read -n 1 -s -r -p "设置完成！按任意键返回。"
}

export -f run_setup
