# Rime 配置备份工具

一个简单而强大的Rime输入法配置备份工具，支持多平台，提供自动检测、备份管理等功能。

## 功能特点

- 🖥️ 多平台支持：自动识别macOS、Linux和Windows系统
- 🔍 智能检测：自动检测不同输入法前端（iBus、Fcitx、Fcitx5等）的配置目录
- 💾 灵活备份：支持标准备份和自定义名称备份
- ☁️ iCloud集成：在macOS上支持备份到iCloud云盘
- 📋 备份管理：提供备份列表查看、清理和快速访问功能
- 🚀 全局命令：支持设置全局命令别名，方便使用

## 安装方法

1. 下载脚本：
```bash
curl -O https://raw.githubusercontent.com/yourusername/rime-backup/main/simple_backup.sh
```

2. 添加执行权限：
```bash
chmod +x simple_backup.sh
```

3. 运行首次设置：
```bash
./simple_backup.sh setup
```

## 使用方法

### 基本命令

- 标准备份：
```bash
./simple_backup.sh
```

- 创建带自定义名称的备份：
```bash
./simple_backup.sh "备份说明"
```

- 查看备份列表：
```bash
./simple_backup.sh list
```

- 查看备份列表（包含完整路径）：
```bash
./simple_backup.sh list full
```

- 清理旧备份（保留最近5个）：
```bash
./simple_backup.sh clean
```

- 打开指定备份文件夹：
```bash
./simple_backup.sh open <序号>
```

### 全局命令设置

首次运行时会提示是否设置全局命令。如果选择设置，可以自定义命令名称（默认为`rimebak`）。

设置完成后，需要重新加载终端配置或重启终端：
```bash
source ~/.zshrc  # 如果使用zsh
# 或
source ~/.bashrc  # 如果使用bash
```

## 支持的平台

- macOS
- Linux（支持iBus、Fcitx、Fcitx5）
- Windows（支持MSYS2、Cygwin、Git Bash等环境）

## 配置说明

配置文件保存在 `~/.config/rime_backup/config.sh`，包含：
- Rime配置目录路径
- 备份存储位置

## 注意事项

1. 首次运行时会进行环境检测和配置设置
2. 在macOS上，如果检测到iCloud云盘，会询问是否将备份保存到iCloud
3. 备份文件命名格式：`Rime_[名称]_YYYYMMDD_HHMMSS`
4. 清理功能默认保留最近5个备份

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

---

<div align="left">

  [![GitHub](https://img.shields.io/badge/GitHub-Jascenn-green)](https://github.com/Jascenn)
  [![Email](https://img.shields.io/badge/Email-联系我-blue)](mailto:darkerrouge@gmail.com)
  [![Stars](https://img.shields.io/github/stars/Jascenn?style=social)](https://github.com/Jascenn)
  [![Followers](https://img.shields.io/github/followers/Jascenn?style=social)](https://github.com/Jascenn)

</div>

<div align="center">

| GitHub Stats | Top Languages |
|---|---|
| <img src="https://github-readme-stats.vercel.app/api?username=Jascenn&show_icons=true&theme=radical&hide_border=true&include_all_commits=true&count_private=true" alt="GitHub Stats" /> | <img src="https://github-readme-stats.vercel.app/api/top-langs/?username=Jascenn&layout=compact&theme=radical&hide_border=true&langs_count=6" alt="Top Languages" /> |