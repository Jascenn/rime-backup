# Windows 快速上手

RimeBak 是一个 Bash 脚本，Windows 用户需要在类 Unix 环境（WSL 或 Git Bash/Cygwin）中运行。本指南提供两套方案，你可以选择任意一种。

## 方案一：使用 WSL（推荐）

### 1. 准备 WSL 环境

1. 打开 PowerShell（以管理员身份）
2. 执行：
   ```powershell
   wsl --install
   ```
3. 根据提示重启电脑，并为 Linux 发行版设置用户名密码

### 2. 在 WSL 中安装 RimeBak

```bash
# 以下操作在 WSL 终端内执行
cd ~
git clone git@github.com:Jascenn/rime-backup.git
cd rime-backup
bash scripts/rimebak_onboarding.sh
```

引导脚本会帮助你：
- 检查 `bash`、`rsync` 等依赖
- 是否调用 `./install.sh` 安装为全局命令（`rimebak`）
- 运行 `rimebak setup` 并选择备份目录
- 演示常用命令及 `undo` 回滚

> 备份目录默认在 WSL 内部，例如 `~/Rime_backups`。如需与 Windows 主系统共享，可以选择 `/mnt/c/Users/<你的用户名>/Documents/Rime_backups`。

### 3. 常用命令

```bash
rimebak setup
rimebak              # 创建备份
rimebak list full    # 查看备份
rimebak clean        # 交互式选择删除备份（支持 1-3、latest 等）
rimebak undo         # 恢复最近一次 clean
rimebak open latest  # 打开最新备份（会调用 Windows 资源管理器）
```

## 方案二：使用 Git Bash / Cygwin

### 1. 安装环境

- [Git for Windows](https://git-scm.com/download/win)（包含 Git Bash）
- 或 [Cygwin](https://www.cygwin.com/install.html) 并勾选 `rsync` 包

### 2. 下载项目

在 Git Bash 或 Cygwin 终端中执行：
```bash
cd "$HOME"
git clone git@github.com:Jascenn/rime-backup.git
cd rime-backup
bash scripts/rimebak_onboarding.sh
# 若想生成独立 .exe 供用户双击，可在 PowerShell 中运行：
#   powershell -ExecutionPolicy Bypass -File scripts\build-onboarding-exe.ps1
# 前提：已安装 ps2exe（Install-Module ps2exe）
```

引导脚本会：
- 验证 `bash`、`rsync` 是否就绪
- 询问是否运行 `./install.sh`（需要管理员权限，可选）
- 引导执行 `./rimebak.sh setup`
- 提供常用命令示例

### 3. 注意事项

- 脚本会自动把 Unix 路径转为 Windows 路径，并通过 `cmd.exe /c start` 打开资源管理器
- 如果提示找不到 `cygpath`，可以通过 `pacman -S cygpath`（MSYS2）或重新安装 Git Bash/Cygwin 获得
- 保证备份目录路径无中文或空格更稳妥，例如 `C:/Rime_backups`

### 4. 常用命令

```bash
./rimebak.sh setup          # 若未全局安装，可直接在仓库内运行
./rimebak.sh                # 创建备份
./rimebak.sh list full
./rimebak.sh clean          # 输入 1-3、latest 或 all 等选择项
./rimebak.sh undo
./rimebak.sh open latest
```

## 常见问题

| 问题 | 解决方案 |
| --- | --- |
| `bash: rsync: command not found` | 在 Git Bash/Cygwin 安装 `rsync`；WSL 中用 `sudo apt install rsync` |
| `cmd.exe /c start` 未能打开目录 | 确保终端有权限访问该路径；可手动在资源管理器输入备份目录名 |
| 想排除某些文件夹 | 编辑 `~/.config/rime_backup/excludes.txt`，每行一个模式，使用 `!pattern` 取消默认排除 |
| 清理后想恢复 | 运行 `rimebak undo`，或手动检查 `<备份目录>/.rimebak_trash` |
| 想生成可执行文件 | PowerShell 执行 `powershell -ExecutionPolicy Bypass -File scripts\build-onboarding-exe.ps1`，需先 `Install-Module ps2exe` |

## 下一步

- 建议把 `rimebak` 命令加入计划任务（Windows 任务计划程序或 Linux `crontab`），实现定期备份
- 如需进一步自定义，可阅读项目根目录下的 README 了解全部命令

按照以上步骤，Windows 用户也能轻松完成 Rime 配置的自动备份。祝使用顺利！
