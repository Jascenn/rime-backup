#!/bin/bash

# RimeBak Path Detection Library (Auto-Discovery)
# ============================================================================

# 自动判断 Rime 配置文件夹
detect_rime_dir() {
    if [ "$(uname)" = "Darwin" ]; then
        echo "$HOME/Library/Rime"
    elif [ "$(uname)" = "Linux" ]; then
        if [ -d "$HOME/.config/ibus/rime" ]; then
            echo "$HOME/.config/ibus/rime"
        elif [ -d "$HOME/.config/fcitx/rime" ]; then
            echo "$HOME/.config/fcitx/rime"
        elif [ -d "$HOME/.local/share/fcitx5/rime" ]; then
            echo "$HOME/.local/share/fcitx5/rime"
        else
            echo "$HOME/.config/rime"
        fi
    elif [[ "$(uname -s)" == *MINGW* ]] || [[ "$(uname -s)" == *CYGWIN* ]]; then
        if [ -d "$APPDATA/Rime" ]; then
            echo "$APPDATA/Rime"
        else
            echo "$HOME/AppData/Roaming/Rime"
        fi
    else
        echo "$HOME/.config/rime"
    fi
}

# 智能扫描备份位置 (PRD v3.4 Logic)
# 优先级: P0(已有备份) > P1(外置存储) > P2(iCloud) > P3(本地)
# 输出: 全局变量 DISCOVERED_PATHS, DISCOVERED_NAMES, RECOMMENDED_PATH
DISCOVERED_PATHS=()
DISCOVERED_NAMES=()
RECOMMENDED_PATH=""

smart_discover_backups() {
    # 重置全局变量
    DISCOVERED_PATHS=()
    DISCOVERED_NAMES=()
    RECOMMENDED_PATH=""
    
    # 常见的目录名
    local -a patterns=(
        "Rime_Auto_Backup"
        "Rime_auto_backup"
        "Rime-部分/Rime_Auto_Backup"
        "Rime-部分/Rime_auto_backup"
        "iCloud offline/Rime-部分/Rime_Auto_Backup"
    )

    log_debug "正在扫描备份源..."

    # 1. 检测外置硬盘 (P1)
    if [ "$(uname)" = "Darwin" ]; then
        for vol in /Volumes/*; do
            if [[ -d "$vol" && "$vol" != "/Volumes/Macintosh HD" && -w "$vol" ]]; then
                for p in "${patterns[@]}"; do
                    local check_path="$vol/$p"
                    if [[ -d "$check_path" ]]; then
                        local count=$(find "$check_path" -maxdepth 1 -type d -name "Rime_*" 2>/dev/null | wc -l | tr -d ' ')
                        if [[ $count -gt 0 ]]; then
                            DISCOVERED_PATHS+=("$check_path")
                            DISCOVERED_NAMES+=("外置: ${vol##*/} ($count 备份)")
                            [[ -z "$RECOMMENDED_PATH" ]] && RECOMMENDED_PATH="$check_path"
                        fi
                    fi
                done
            fi
        done
    fi

    # 2. 检测 iCloud (P2)
    local icloud_base="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    if [[ -d "$icloud_base" ]]; then
        for p in "${patterns[@]}"; do
            local check_path="$icloud_base/$p"
            if [[ -d "$check_path" ]]; then
                local count=$(find "$check_path" -maxdepth 1 -type d -name "Rime_*" 2>/dev/null | wc -l | tr -d ' ')
                if [[ $count -gt 0 ]]; then
                    DISCOVERED_PATHS+=("$check_path")
                    DISCOVERED_NAMES+=("iCloud 云盘 ($count 备份)")
                    [[ -z "$RECOMMENDED_PATH" ]] && RECOMMENDED_PATH="$check_path"
                fi
            fi
        done
    fi

    # 3. 本地 (P3)
    local local_path="$HOME/Documents/Rime_auto_backup"
    if [[ -d "$local_path" ]]; then
        local count=$(find "$local_path" -maxdepth 1 -type d -name "Rime_*" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $count -gt 0 ]]; then
            DISCOVERED_PATHS+=("$local_path")
            DISCOVERED_NAMES+=("本地目录 ($count 备份)")
            [[ -z "$RECOMMENDED_PATH" ]] && RECOMMENDED_PATH="$local_path"
        fi
    fi
}
