#!/bin/bash

# RimeBak Operations Core (Backup / Restore / Cleanup)
# ============================================================================

# 创建备份 (PRD v3.4 增强: 备注与路径显式化)
do_backup() {
    local backup_name="${1:-}"
    local comment="${2:-}"
    local date_time=$(date +"%Y%m%d_%H%M%S")
    
    # 路径显式化
    log_info "源目录: $SOURCE_DIR"
    log_info "备份基准目录: $BACKUP_BASE"
    
    if [ -n "$backup_name" ]; then
        backup_name="${backup_name// /_}"
        BACKUP_DIR="$BACKUP_BASE/Rime_${backup_name}_${date_time}"
    else
        BACKUP_DIR="$BACKUP_BASE/Rime_backup_${date_time}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "[预览] 将创建目录: $BACKUP_DIR"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"
    log_info "正在同步文件..." "$BACKUP_DIR"

    BACKUP_IN_PROGRESS=1
    
    local -a rsync_args=(-av)
    for pattern in "${EXCLUDE_PATTERNS[@]+"${EXCLUDE_PATTERNS[@]}"}"; do
        rsync_args+=("--exclude=$pattern")
    done

    if rsync "${rsync_args[@]}" "$SOURCE_DIR/" "$BACKUP_DIR/"; then
        # 写入备注 (PRD v3.3)
        if [[ -n "$comment" ]]; then
            echo "备注: $comment" > "$BACKUP_DIR/BACKUP_NOTE.md"
            echo "创建时间: $(date)" >> "$BACKUP_DIR/BACKUP_NOTE.md"
        fi
        log_success "备份完成"
    else
        log_error "备份失败"
        rm -rf "$BACKUP_DIR"
    fi

    BACKUP_IN_PROGRESS=0
}

# 搜集所有备份 (扩展版：支持多种命名格式和多个目录)
gather_backups() {
    local -a standard_entries=()
    local -a legacy_entries=()
    
    # 需要扫描的目录列表
    local -a scan_dirs=("$BACKUP_BASE")
    
    # 添加额外的已知备份目录
    local extra_dirs=(
        "/Volumes/Mypssd/iCloud offline/Rime-部分"
        "/Volumes/Mypssd/iCloud offline/Rime-部分/Rime_Auto_Backup"
    )
    for dir in "${extra_dirs[@]}"; do
        [[ -d "$dir" ]] && scan_dirs+=("$dir")
    done
    
    log_debug "正在扫描: ${scan_dirs[*]}"

    for scan_base in "${scan_dirs[@]}"; do
        while IFS= read -r entry; do
            local name=${entry##*/}
            
            # 格式1: 标准格式 Rime_*_YYYYMMDD_HHMMSS
            if [[ $name =~ ^Rime_(.+)_([0-9]{8})_([0-9]{6})$ ]]; then
                local key="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
                standard_entries+=("$key"$'\t'"$entry")
            # 格式2: 旧格式 Rime-* 或 Rime_*（无时间戳，排除子目录中的 Rime_Auto_Backup）
            elif [[ $name =~ ^Rime[-_] && $name != "Rime_Auto_Backup" ]]; then
                # 尝试从修改时间获取排序键
                local mtime=$(stat -f "%m" "$entry" 2>/dev/null || echo "0")
                legacy_entries+=("$mtime"$'\t'"$entry")
            fi
        done < <(find "$scan_base" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null)
    done

    BACKUP_LIST=()
    
    # 先添加标准格式（按时间戳排序）
    if [ ${#standard_entries[@]} -gt 0 ]; then
        local sorted=$(printf '%s\n' "${standard_entries[@]}" | LC_ALL=C sort -r)
        while IFS=$'\t' read -r key path; do
            [[ -n "$key" ]] && BACKUP_LIST+=("$path")
        done <<<"$sorted"
    fi
    
    # 再添加旧格式（按修改时间排序）
    if [ ${#legacy_entries[@]} -gt 0 ]; then
        local sorted=$(printf '%s\n' "${legacy_entries[@]}" | LC_ALL=C sort -rn)
        while IFS=$'\t' read -r key path; do
            [[ -n "$key" ]] && BACKUP_LIST+=("$path")
        done <<<"$sorted"
    fi
    
    BACKUP_TOTAL=${#BACKUP_LIST[@]}
}

# 列表展示 (增强版)
list_backups_ui() {
    local show_full="${1:-false}"
    gather_backups
    
    printf "\n${BLUE}可用备份列表 (共 $BACKUP_TOTAL 个)${NC}\n"
    printf "────────────────────────────────────────\n"
    printf "%-6s %-19s %s\n" "序号" "创建时间" "备注/名称"
    
    local idx=1
    for path in "${BACKUP_LIST[@]}"; do
        local name=${path##*/}
        if [[ $name =~ _([0-9]{8})_([0-9]{6})$ ]]; then
            local date_str="${BASH_REMATCH[1]}"
            local time_str="${BASH_REMATCH[2]}"
            local formatted="${date_str:0:4}-${date_str:4:2}-${date_str:6:2} ${time_str:0:2}:${time_str:2:2}"
            
            local display_name="标准备份"
            if [[ -f "$path/BACKUP_NOTE.md" ]]; then
                display_name=$(head -n 1 "$path/BACKUP_NOTE.md" | sed 's/^[^:]*: //')
            elif [[ $name != Rime_backup_* ]]; then
                display_name=$(echo "$name" | sed -E 's/^Rime_(.+)_[0-9]{8}_[0-9]{6}$/\1/' | tr '_' ' ')
            fi
            
            printf "[%-2d]  %-19s %s\n" "$idx" "$formatted" "$display_name"
            [[ "$show_full" == "true" ]] && printf "      ${GRAY}路径: %s${NC}\n" "$path"
        fi
        ((idx++))
    done
    echo ""
}

# 恢复备份
do_restore() {
    local target="${1:-latest}"
    gather_backups
    
    [[ $BACKUP_TOTAL -eq 0 ]] && { log_error "无备份可恢复"; return 1; }
    
    local idx
    if [[ "$target" == "latest" ]]; then idx=1; else idx=$target; fi
    
    local path="${BACKUP_LIST[$((idx-1))]}"
    log_info "准备恢复: ${path##*/}"
    
    # 恢复前自动备份
    log_info "正在进行恢复前自动对冲备份..."
    do_backup "Pre_Restore_Auto" "自动对冲：恢复 ${path##*/} 前的配置状态"
    
    log_info "正在执行覆盖恢复..."
    if rsync -av --delete "$path/" "$SOURCE_DIR/"; then
        log_success "恢复成功。请重新部署 Rime。"
    else
        log_error "恢复失败"
    fi
}

# 解析索引 (保留原逻辑扩展)
resolve_backup_index() {
    local token="$1"
    [[ "$token" == "latest" ]] && { echo 1; return; }
    [[ "$token" == "oldest" ]] && { echo "$BACKUP_TOTAL"; return; }
    echo "$token"
}

# 交互式清理备份 (方向键选择)
clean_backups() {
    gather_backups
    
    if [[ $BACKUP_TOTAL -le 1 ]]; then
        log_warn "当前备份数量不超过 1，无需清理"
        return 0
    fi
    
    # 初始化选择状态数组
    local -a selected=()
    for ((i=0; i<BACKUP_TOTAL; i++)); do
        selected[$i]=false
    done
    
    local current=0
    
    while true; do
        clear_screen
        show_banner
        printf '%b\n' "${BLUE}选择要删除的备份${NC}"
        printf "────────────────────────────────────────\n"
        printf '%b\n\n' "${GRAY}空格键 标记/取消 | ↑↓/jk 移动 | Enter 确认 | q 取消${NC}"
        
        local idx=0
        for path in "${BACKUP_LIST[@]}"; do
            local name=${path##*/}
            local marker=" "
            [[ "${selected[$idx]}" == "true" ]] && marker="✗"
            
            if [[ $idx -eq $current ]]; then
                if [[ "${selected[$idx]}" == "true" ]]; then
                    printf '%b\n' "  ${CYAN}▶${NC} [${RED}${marker}${NC}] $name"
                else
                    printf '%b\n' "  ${CYAN}▶${NC} [$marker] $name"
                fi
            else
                if [[ "${selected[$idx]}" == "true" ]]; then
                    printf '%b\n' "    [${RED}${marker}${NC}] $name"
                else
                    printf "    [%s] %s\n" "$marker" "$name"
                fi
            fi
            ((idx++))
        done
        
        # 统计已选数量
        local count=0
        for s in "${selected[@]}"; do
            [[ "$s" == "true" ]] && ((count++))
        done
        echo ""
        printf '%b\n' "已选择: ${YELLOW}${count}${NC} 个"
        
        hide_cursor
        key=$(read_key)
        show_cursor
        drain_pending_input
        
        case "$key" in
            UP) ((current > 0)) && ((current--)) || current=$((BACKUP_TOTAL-1)) ;;
            DOWN) ((current < BACKUP_TOTAL-1)) && ((current++)) || current=0 ;;
            SPACE)
                # 空格键切换选择状态
                if [[ "${selected[$current]}" == "true" ]]; then
                    selected[$current]=false
                else
                    selected[$current]=true
                fi
                ;;
            FORWARD|ENTER)
                # 确认删除
                if [[ $count -eq 0 ]]; then
                    log_warn "未选择任何备份"
                    sleep 1
                    continue
                fi
                
                echo ""
                printf "${RED}确认删除 %d 个备份? (y/N): ${NC}" "$count"
                read -n 1 confirm
                echo ""
                
                if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                    echo "已取消"
                    sleep 1
                    continue
                fi
                
                # 执行删除
                local trash_dir="$BACKUP_BASE/.rimebak_trash"
                mkdir -p "$trash_dir"
                
                local deleted=0
                for ((i=0; i<BACKUP_TOTAL; i++)); do
                    if [[ "${selected[$i]}" == "true" ]]; then
                        local path="${BACKUP_LIST[$i]}"
                        local name="${path##*/}"
                        if mv "$path" "$trash_dir/$name"; then
                            log_success "已移除: $name"
                            ((deleted++))
                        fi
                    fi
                done
                
                log_info "共删除 $deleted 个备份"
                return 0
                ;;
            BACK|QUIT)
                echo ""
                echo "已取消"
                return 0
                ;;
        esac
    done
}

# 统计信息
show_stats() {
    gather_backups
    
    clear_screen
    show_banner
    printf "${BLUE}备份统计${NC}\n"
    printf "────────────────────────────────────────\n"
    
    printf "源目录: ${CYAN}%s${NC}\n" "$SOURCE_DIR"
    printf "备份目录: ${CYAN}%s${NC}\n" "$BACKUP_BASE"
    echo ""
    
    printf "备份总数: ${GREEN}%d${NC}\n" "$BACKUP_TOTAL"
    
    # 计算总占用空间
    if [[ $BACKUP_TOTAL -gt 0 ]]; then
        local total_size=$(du -sh "$BACKUP_BASE" 2>/dev/null | cut -f1)
        printf "总占用空间: ${YELLOW}%s${NC}\n" "$total_size"
        
        # 最新和最旧备份
        local newest="${BACKUP_LIST[0]##*/}"
        local oldest="${BACKUP_LIST[$((BACKUP_TOTAL-1))]##*/}"
        echo ""
        printf "最新备份: %s\n" "$newest"
        printf "最旧备份: %s\n" "$oldest"
    fi
    
    # Git 状态
    echo ""
    if [[ -d "$BACKUP_BASE/.git" ]]; then
        printf "Git 状态: ${GREEN}已启用${NC}\n"
        local remote=$(cd "$BACKUP_BASE" && git remote get-url origin 2>/dev/null || echo "未绑定")
        printf "远程仓库: %s\n" "$remote"
    else
        printf "Git 状态: ${GRAY}未初始化${NC}\n"
    fi
    
    printf "────────────────────────────────────────\n"
}

export -f do_backup gather_backups list_backups_ui do_restore resolve_backup_index clean_backups show_stats
