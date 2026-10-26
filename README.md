# RimeBak

一个简单而强大的 Rime 输入法配置备份工具，支持多平台，提供自动检测、备份管理、版本恢复、Git 同步等功能。

```
   ____  _                ____        _    
  |  _ \(_)_ __ ___   ___| __ )  __ _| | __
  | |_) | | '_ ` _ \ / _ \  _ \ / _` | |/ /
  |  _ <| | | | | | |  __/ |_) | (_| |   < 
  |_| \_\_|_| |_| |_|\___|____/ \__,_|_|\_\
```

## ✨ 功能特点

- 🖥️ **多平台支持**：自动识别 macOS、Linux 和 Windows 系统
- 🔍 **智能检测**：自动检测不同输入法前端（iBus、Fcitx、Fcitx5等）的配置目录
- 💾 **灵活备份**：支持标准备份和自定义名称备份
- 🔄 **版本恢复**：`rimebak restore` 恢复指定版本备份
- 🌐 **Git 同步**：`rimebak git` 增量备份到 GitHub，解决本地空间不足
- 📊 **备份统计**：`rimebak stats` 查看备份总数、大小、Git 状态
- ☁️ **iCloud 集成**：在 macOS 上支持备份到 iCloud 云盘
- 📋 **备份管理**：提供备份列表查看、交互式清理与快速访问功能
- 🧰 **回滚保障**：清理时将备份移入临时回收站，可一键撤销
- 🎨 **交互式菜单**：支持 ↑↓ 箭头键和数字键导航
- 🔍 **预览模式**：`--dry-run` 预览操作，不实际执行

## 📦 安装方法

### Homebrew (推荐)

```bash
brew tap Jascenn/rimebak
brew install rimebak
```

### 手动安装

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/Jascenn/rime-backup/main/rimebak.sh
chmod +x rimebak.sh

# 安装到 PATH (可选)
sudo mv rimebak.sh /usr/local/bin/rimebak
```

### 首次设置

```bash
rimebak setup
```

## 🚀 快速开始

```bash
# 进入交互式菜单
rimebak

# 创建备份
rimebak "升级前备份"

# 查看备份列表
rimebak list

# 恢复指定备份
rimebak restore 1
rimebak restore latest

# Git 同步
rimebak git init              # 初始化 Git 仓库
rimebak git remote <url>      # 设置 GitHub 仓库
rimebak git sync              # 提交并推送

# 查看统计
rimebak stats

# 查看帮助
rimebak --help
```

## 📋 命令速查

| 命令 | 说明 |
|------|------|
| `rimebak` | 进入交互式菜单 |
| `rimebak <名称>` | 创建带名称的备份 |
| `rimebak list [full]` | 列出所有备份 |
| `rimebak restore <序号>` | 恢复指定备份 |
| `rimebak clean` | 交互式清理备份 |
| `rimebak undo` | 撤销上次清理 |
| `rimebak open <序号>` | 打开备份文件夹 |
| `rimebak stats` | 查看备份统计 |
| `rimebak setup` | 重新配置 |

### Git 同步命令

| 命令 | 说明 |
|------|------|
| `rimebak git init` | 初始化 Git 仓库 |
| `rimebak git remote <url>` | 设置远程仓库 |
| `rimebak git sync` | 提交并推送 |
| `rimebak git pull` | 从远程拉取 |
| `rimebak git status` | 查看 Git 状态 |

### 选项

| 选项 | 说明 |
|------|------|
| `--dry-run` | 预览操作，不实际执行 |
| `--debug` | 显示调试信息 |
| `--help, -h` | 显示帮助 |
| `--version, -v` | 显示版本 |

## 🖥️ 支持的平台

| 平台 | 支持状态 | Rime 配置目录 |
|------|----------|---------------|
| **macOS** | ✅ 原生支持 | `~/Library/Rime/` |
| **Linux (iBus)** | ✅ 支持 | `~/.config/ibus/rime/` |
| **Linux (Fcitx5)** | ✅ 支持 | `~/.local/share/fcitx5/rime/` |
| **Windows (WSL/Git Bash)** | ✅ 支持 | `$APPDATA/Rime/` |

## 📖 文档

- [macOS 快速上手](docs/quickstart-macos.md)
- [Windows 快速上手](docs/quickstart-windows.md)

## ⚙️ 配置

配置文件保存在 `~/.config/rime_backup/config.sh`，包含：

- Rime 配置目录路径
- 备份存储位置

排除规则文件：`~/.config/rime_backup/excludes.txt`

## 📝 更新日志

### v2.1.0

- 新增 `rimebak restore` 恢复指定版本备份
- 新增 `rimebak git` Git 增量备份同步
- 新增 `rimebak stats` 备份统计
- 新增 Homebrew 安装支持
- 新增彩色 ASCII Art Banner
- 新增交互式菜单（↑↓ 键导航）
- 新增 `--dry-run` 预览模式
- 新增 `--debug` 调试模式
- 增强日志系统（彩色输出）

### v1.0.0

- 初始版本
- 多平台支持
- 备份、列表、清理、撤销等基本功能

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目原创代码采用 [MIT License](LICENSE)。第三方依赖、上游项目与外部素材继续遵循各自许可证。

---

<div align="left">

[![GitHub](https://img.shields.io/badge/GitHub-Jascenn-green)](https://github.com/Jascenn)
[![Email](https://img.shields.io/badge/Email-联系我-blue)](mailto:1286324609@qq.com)
[![Stars](https://img.shields.io/github/stars/Jascenn/rime-backup?style=social)](https://github.com/Jascenn/rime-backup)

</div>

## 贡献与安全

- 参与开发前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。
- 安全问题请按 [SECURITY.md](SECURITY.md) 私下报告，不要开公开 Issue。
