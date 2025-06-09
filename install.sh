#!/bin/bash

set -euo pipefail

# RimeBak 安装脚本

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="rimebak.sh"
TARGET_NAME="rimebak"

# 获取脚本所在目录
SCRIPT_SOURCE_DIR=$(cd "$(dirname "$0")" && pwd)
SCRIPT_PATH="$SCRIPT_SOURCE_DIR/$SCRIPT_NAME"

echo "RimeBak 安装程序"
echo "------------------"

# 检查 rimebak.sh 是否存在
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "错误: 找不到 '${SCRIPT_NAME}' 脚本。请确保 '${SCRIPT_NAME}' 与本安装脚本在同一目录下。"
    exit 1
fi

# 检查安装目录是否存在，如果不存在则创建
if [ ! -d "$INSTALL_DIR" ]; then
    echo "创建安装目录: $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "错误: 无法创建安装目录。请检查权限或手动创建: sudo mkdir -p $INSTALL_DIR"
        exit 1
    fi
fi

echo "正在复制 '${SCRIPT_NAME}' 到 '${INSTALL_DIR}/${TARGET_NAME}'..."
sudo cp "$SCRIPT_PATH" "$INSTALL_DIR/$TARGET_NAME"

if [ $? -ne 0 ]; then
    echo "错误: 复制文件失败。请检查权限。"
    exit 1
fi

echo "正在设置执行权限..."
sudo chmod +x "$INSTALL_DIR/$TARGET_NAME"

if [ $? -ne 0 ]; then
    echo "错误: 设置执行权限失败。"
    exit 1
fi

echo "RimeBak 已成功安装到 '${INSTALL_DIR}/${TARGET_NAME}'。"
echo "您现在可以在终端中直接运行 'rimebak' 命令。"
echo ""
echo "首次使用或需要重新配置，请运行:"
echo "  rimebak setup"
echo ""
echo "更多使用方法，请查看项目的 README.md 文件。"

exit 0 