#!/bin/bash

# RimeBak Doctor & Legacy Cleanup Module
# ============================================================================

LEGACY_PATHS=(
    "/usr/local/bin/rimebak"
    "$HOME/.local/bin/rimebak"
)

# 检查冲突
check_conflicts() {
    local current_bin=$(command -v rimebak 2>/dev/null)
    local cur_script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    
    log_debug "检查命令版本冲突..."
    for path in "${LEGACY_PATHS[@]}"; do
        if [[ -f "$path" && "$path" != "$cur_script_path" ]]; then
            log_warn "检测到潜在的旧版本文件: $path"
            return 1
        fi
    done
    return 0
}

# 诊断程序
run_doctor() {
    clear_screen
    show_banner
    printf "${BLUE}系统诊断程序${NC}\n"
    printf "────────────────────────────────────────\n"
    
    local issues=0
    
    # 1. 检查环境变量
    printf "[1] 环境检查: "
    if [[ -n "$SOURCE_DIR" && -d "$SOURCE_DIR" ]]; then
        printf "${GREEN}✓ OK${NC}\n"
    else
        printf "${RED}✗ 目录不存在${NC}\n"
        ((issues++))
    fi
    
    # 2. 检查旧文件
    printf "[2] 冲突检查: "
    local cur_script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local found_old=()
    for p in "${LEGACY_PATHS[@]}"; do
        [[ -f "$p" && "$p" != "$cur_script_path" ]] && found_old+=("$p")
    done
    
    if [[ ${#found_old[@]} -eq 0 ]]; then
        printf "${GREEN}✓ 无冲突${NC}\n"
    else
        printf "${YELLOW}! 发现旧版本${NC}\n"
        for p in "${found_old[@]}"; do printf "      - %s\n" "$p"; done
        ((issues++))
    fi
    
    # 3. 结果汇总
    printf "────────────────────────────────────────\n"
    if [[ $issues -eq 0 ]]; then
        log_success "一切正常！你的 RimeBak 环境非常健康。"
    else
        log_warn "发现 $issues 个潜在问题。"
        read -p "是否尝试自动修复? (y/N): " confirm
        if [[ "$confirm" =~ ^[yY]$ ]]; then
            fix_issues "${found_old[@]}"
        fi
    fi
    read -n 1 -s -r -p "按任意键返回..."
}

# 自动修复
fix_issues() {
    local old_files=("$@")
    for f in "${old_files[@]}"; do
        log_info "正在移除: $f"
        sudo rm -f "$f" || log_error "无法删除 $f，请手动操作。"
    done
    log_success "修复尝试已完成。"
}

export -f check_conflicts run_doctor fix_issues
