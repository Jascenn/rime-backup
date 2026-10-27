#!/bin/bash

# RimeBak Git Provider Module
# ============================================================================

# 初始化 Git 仓库
git_init() {
    if [ -d "$BACKUP_BASE/.git" ]; then
        log_warn "Git 仓库已存在"
        return 0
    fi
    
    log_info "正在 $BACKUP_BASE 初始化 Git 仓库..."
    cd "$BACKUP_BASE" || return 1
    
    if [[ "$DRY_RUN" != "true" ]]; then
        git init
        cat > .gitignore << 'EOF'
.rimebak_trash/
*.log
.DS_Store
EOF
        git add .
        git commit -m "Initial commit: RimeBak backup repository"
        log_success "Git 仓库初始化完成"
    else
        log_warn "[预览] 跳过初始化"
    fi
}

# 绑定远程
git_remote() {
    local url="$1"
    [[ ! -d "$BACKUP_BASE/.git" ]] && { log_error "请先运行 git init"; return 1; }
    [[ -z "$url" ]] && { log_error "用法: rimebak git remote <url>"; return 1; }
    
    cd "$BACKUP_BASE" || return 1
    if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "$url"
    else
        git remote add origin "$url"
    fi
    log_success "远程仓库已设置为: $url"
}

# 增量同步
git_sync() {
    [[ ! -d "$BACKUP_BASE/.git" ]] && { log_error "请先运行 git init"; return 1; }
    
    cd "$BACKUP_BASE" || return 1
    local changes=$(git status --porcelain)
    if [ -z "$changes" ]; then
        log_info "无需同步：工作区是干净的"
        return 0
    fi
    
    log_info "正在提交增量变更..."
    if [[ "$DRY_RUN" != "true" ]]; then
        git add .
        git commit -m "Backup Push: $(date '+%Y-%m-%d %H:%M:%S')"
        
        if git remote get-url origin >/dev/null 2>&1; then
            log_info "正在向云端推送..."
            git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
            log_success "云端同步成功"
        else
            log_warn "未绑定远程仓库，仅本地提交。使用 'git remote' 绑定。"
        fi
    else
        log_warn "[预览] 跳过 Git 提交"
    fi
}

# 状态展示
git_status_ui() {
    [[ ! -d "$BACKUP_BASE/.git" ]] && { log_error "Git 未初始化"; return 1; }
    
    cd "$BACKUP_BASE" || return 1
    printf "\n${BLUE}Git 同步状态${NC}\n"
    printf "────────────────────────────────────────\n"
    printf "远程: %s\n" "$(git remote get-url origin 2>/dev/null || echo "未绑定")"
    printf "分支: %s\n" "$(git branch --show-current 2>/dev/null)"
    printf "最近提交: %s\n" "$(git log -1 --format="%h %s" 2>/dev/null || echo "无")"
    echo ""
    git status --short
}

export -f git_init git_remote git_sync git_status_ui
