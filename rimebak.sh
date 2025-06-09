#!/bin/bash

set -euo pipefail

# Auther: 凌一 (Jascenn)
# GitHub: https://github.com/Jascenn
# Email: darkerrouge@gmail.com
# Date：2025-06-09
# WeChat：Help000000

# Rime 备份工具 - 简单版本
# 用法: ./rimebak.sh [选项]
#   无选项          - 执行标准备份
#   clean           - 备份并清理旧备份，只保留最近5个
#   list            - 列出所有备份 (简洁版)
#   list full       - 列出所有备份 (包含完整路径)
#   open 序号      - 打开指定序号的备份文件夹 (例如: ./rimebak.sh open 1)
#   备份名称        - 使用指定名称创建备份 (例如: ./rimebak.sh '修改配置前')
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
elif [ "$1" = "setup" ]; then
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

# 创建备份
DATE_TIME=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR=""

do_backup() {
    local backup_name="$1"
    
    if [ -n "$backup_name" ]; then
        # 使用自定义名称创建备份目录
        backup_name="${backup_name// /_}" # 替换空格为下划线
        BACKUP_DIR="$BACKUP_BASE/Rime_${backup_name}_${DATE_TIME}"
    else
        # 使用默认名称创建备份目录
        BACKUP_DIR="$BACKUP_BASE/Rime_backup_${DATE_TIME}"
    fi
    
    mkdir -p "$BACKUP_DIR"
    rsync -av --exclude="*.sh" "$SOURCE_DIR/" "$BACKUP_DIR/"
    echo "Rime 配置已备份到 $BACKUP_DIR"
}

# 如果是列表命令
if [ "$1" = "list" ]; then
    # 检查是否需要显示完整路径
    show_full_path=false
    if [ "$2" = "full" ]; then
        show_full_path=true
    fi
    
    echo "可用的 Rime 备份 (按时间从近到远排序):"
    cd "$BACKUP_BASE"
    echo "序号    创建时间            备份名称"
    echo "----------------------------------------------------"
    ls -t | grep -E "Rime_(backup|.+)_[0-9]{8}_[0-9]{6}" | 
    while read -r backup_name; do
        # 提取日期和时间信息
        if [[ $backup_name =~ _([0-9]{8})_([0-9]{6})$ ]]; then
            date_part=${BASH_REMATCH[1]}
            time_part=${BASH_REMATCH[2]}
            
            # 格式化日期和时间
            formatted_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}:${time_part:4:2}"
            
            # 提取备份名称
            if [[ $backup_name =~ ^Rime_backup_ ]]; then
                display_name="标准备份"
            else
                display_name=$(echo "$backup_name" | sed -E 's/Rime_(.+)_[0-9]{8}_[0-9]{6}/\1/' | tr '_' ' ')
            fi
            
            printf "%-8s %-19s %s\n" "[$((++i))]" "$formatted_date" "$display_name"
            
            # 如果需要显示完整路径
            if [ "$show_full_path" = true ]; then
                full_path="$BACKUP_BASE/$backup_name"
                echo "    路径: $full_path"
            fi
        fi
    done
    
    echo ""
    echo "提示: 使用 './rimebak.sh open 序号' 可打开指定备份文件夹"
    if [ "$show_full_path" = false ]; then
        echo "提示: 使用 './rimebak.sh list full' 可查看备份完整路径"
    fi
    
    exit 0
fi

# 如果是清理命令
if [ "$1" = "clean" ]; then
    do_backup
    cd "$BACKUP_BASE"
    ls -t | grep Rime_backup_ | tail -n +6 | xargs -I {} rm -rf {}
    echo "已清理旧备份，保留最近 5 个备份"
    exit 0
fi

# 如果是打开命令
if [ "$1" = "open" ]; then
    if [ -z "$2" ]; then
        echo "错误: 未指定备份序号。用法: ./rimebak.sh open <序号>"
        exit 1
    fi
    
    # 获取序号对应的备份路径
    cd "$BACKUP_BASE"
    backup_path=$(ls -t | grep -E "Rime_(backup|.+)_[0-9]{8}_[0-9]{6}" | sed -n "$2p")
    
    if [ -z "$backup_path" ]; then
        echo "错误: 未找到序号 $2 对应的备份。请运行 './rimebak.sh list' 查看可用备份列表。"
        exit 1
    fi
    
    full_path="$BACKUP_BASE/$backup_path"
    echo "打开备份文件夹: $full_path"
    open "$full_path"
    exit 0
fi

# 默认操作：备份
if [ -n "$1" ]; then
    # 使用自定义名称备份
    do_backup "$1"
    echo "已创建带自定义名称的备份: $1"
else
    # 标准备份
    do_backup
fi

echo "！提示：运行 './rimebak.sh list' 查看所有备份"
echo "！提示：运行 './rimebak.sh clean' 清理旧备份"
echo "！提示：运行 './rimebak.sh 备份名称' 创建带自定义名称的备份"
