# Rime 配置备份工具

一个简单而强大的Rime输入法配置备份工具，支持多平台，提供自动检测、备份管理等功能。

## 功能特点

- 🖥️ 多平台支持：自动识别macOS、Linux和Windows系统
- 🔍 智能检测：自动检测不同输入法前端（iBus、Fcitx、Fcitx5等）的配置目录
- 💾 灵活备份：支持标准备份和自定义名称备份
- ☁️ iCloud集成：在macOS上支持备份到iCloud云盘
- 📋 备份管理：提供备份列表查看、交互式清理与快速访问功能
- 🧰 回滚保障：清理时将备份移入临时回收站，可一键撤销
- 🧾 实时日志：所有关键步骤都会输出 `[rimebak]` 日志，便于追踪
- 🚀 全局命令：支持设置全局命令别名，方便使用

## 快速上手

想要一步步跟着操作？请查看：

- [macOS 快速上手](docs/quickstart-macos.md)
- [Windows 快速上手（WSL / Git Bash / Cygwin）](docs/quickstart-windows.md)

仓库内提供：
- `scripts/rimebak_onboarding.sh`（跨平台 Bash 引导）
- `scripts/rimebak_onboarding.ps1` 和 `rimebak_onboarding.bat`（Windows 快速入口）
- 需要 `.exe` 安装器？在 PowerShell 中运行 `powershell -ExecutionPolicy Bypass -File scripts\build-onboarding-exe.ps1`（需先 `Install-Module ps2exe`）即可生成

## 安装方法

### 推荐安装方式 (macOS & Linux)

1.  **下载脚本和安装文件**：
    ```bash
    curl -O https://raw.githubusercontent.com/Jascenn/rime-backup/main/rimebak.sh
    curl -O https://raw.githubusercontent.com/Jascenn/rime-backup/main/install.sh
    ```
2.  **添加执行权限**：
    ```bash
    chmod +x rimebak.sh install.sh
    ```
3.  **运行安装脚本**：
    ```bash
    ./install.sh
    ```
    安装成功后，`rimebak` 命令将被放置在 `/usr/local/bin` 目录下，您可以直接在任何终端中使用它。

### 手动安装方式 (通用)

1.  **下载脚本**：
    ```bash
    curl -O https://raw.githubusercontent.com/Jascenn/rime-backup/main/rimebak.sh
    ```
2.  **添加执行权限**：
    ```bash
    chmod +x rimebak.sh
    ```
3.  **将脚本移动到 PATH 路径下** (可选，但推荐):
    ```bash
    sudo mv rimebak.sh /usr/local/bin/rimebak
    ```
    或者您可以将其放在任何您喜欢的目录，并确保该目录已添加到您的系统 PATH 环境变量中。

### 首次设置

无论通过哪种方式安装，首次使用或需要重新配置 RimeBak 时，请运行：

```bash
rimebak setup
```

### 关于 `install.sh` 脚本

`install.sh` 是一个便捷的安装脚本，专为 macOS 和 Linux 用户设计，旨在简化 RimeBak 的安装过程。它会自动执行以下操作：

1.  **检查脚本存在**：确保 `rimebak.sh` 脚本与 `install.sh` 位于同一目录。
2.  **创建安装目录**：如果 `/usr/local/bin` 目录不存在，它将尝试创建此目录（通常需要 `sudo` 权限）。`/usr/local/bin` 是系统 PATH 中的一个标准位置，方便您全局调用命令。
3.  **复制并重命名**：将 `rimebak.sh` 脚本复制到 `/usr/local/bin/` 目录下，并将其重命名为更简洁的 `rimebak`。
4.  **设置执行权限**：确保 `rimebak` 文件具有可执行权限，以便系统可以运行它。

**通过使用 `install.sh`，您无需手动复制文件、设置权限，也无需担心 PATH 变量，从而实现 RimeBak 的快速和标准化部署。**

## 使用方法

### 基本命令

- 标准备份：
```bash
./rimebak.sh
```

- 创建带自定义名称的备份：
```bash
./rimebak.sh "备份说明"
```

- 查看备份列表：
```bash
./rimebak.sh list
```

- 查看备份列表（包含完整路径）：
```bash
./rimebak.sh list full
```

- 清理备份（交互式选择，可输入序号/范围/关键字）：
```bash
./rimebak.sh clean
```

- 撤销最近一次清理（将回收站中的备份恢复到原位置）：
```bash
./rimebak.sh undo
```

- 打开指定备份文件夹：
```bash
./rimebak.sh open <序号>
```
  - 支持 `latest`、`oldest`、倒序 `-1`（倒数第一个）等关键字

### 全局命令设置

首次运行时会提示是否设置全局命令。如果选择设置，可以自定义命令名称（默认为`rimebak`）。

设置完成后，需要重新加载终端配置或重启终端：
```bash
source ~/.zshrc  # 如果使用zsh
# 或
source ~/.bashrc  # 如果使用bash
```

## 支持的平台

-   **macOS**: 原生支持。脚本在 macOS 环境下能够自动检测 Rime 配置目录并正常运行。
-   **Linux**: 广泛支持。脚本能够自动检测 iBus, Fcitx, Fcitx5 等主流输入法前端的 Rime 配置目录并运行。
-   **Windows**: 需要类 Unix 环境。您需要在 Windows 上安装并使用 WSL (Windows Subsystem for Linux)、Git Bash 或 Cygwin 等环境来运行此 Bash 脚本。

## Windows 用户安装指南

由于 `rimebak.sh` 是一个 Bash 脚本，您需要在 Windows 上安装一个类 Unix 环境才能运行它。推荐使用以下任一方式：

### 推荐方式：适用于 WSL (Windows Subsystem for Linux)

1.  **安装 WSL 和 Linux 发行版**：
    如果您尚未安装，请按照 Microsoft 官方指南安装 WSL 和您喜欢的 Linux 发行版（例如 Ubuntu）。
    [WSL 安装指南](https://docs.microsoft.com/zh-cn/windows/wsl/install)
2.  **在 WSL 中运行安装脚本**：
    打开您的 WSL 终端，然后按照 [安装方法](#安装方法) 中的 "推荐安装方式 (macOS & Linux)" 步骤进行操作。
    您可以通过文件共享（例如 `\wsl$\%YOUR_DISTRO_NAME%`）或直接在 WSL 中使用 `curl` 下载脚本。

### 替代方式：适用于 Git Bash 或 Cygwin

1.  **安装 Git Bash 或 Cygwin**：
    从官方网站下载并安装 Git Bash 或 Cygwin。这些工具提供了在 Windows 上运行 Bash 脚本的环境。
    - [Git Bash 下载](https://git-scm.com/download/win)
    - [Cygwin 下载](https://www.cygwin.com/install.html)
2.  **在 Git Bash/Cygwin 中运行脚本**：
    打开 Git Bash 或 Cygwin 终端，然后按照 [安装方法](#安装方法) 中的 "手动安装方式 (通用)" 步骤进行操作。
    - 若想在文件管理器中打开备份，脚本会自动调用 `cmd.exe /c start`，无需额外设置。
    - 如果看到路径仍是 Unix 形式，可安装 `cygpath`（Git Bash 默认自带）以便自动转换。
    - 请注意，命令中的路径仍可写成 Unix 风格（例如 `~/AppData/Roaming/Rime`），脚本会自动处理。

## 配置说明

配置文件保存在 `~/.config/rime_backup/config.sh`，包含：
- Rime配置目录路径
- 备份存储位置

## 注意事项

1. 首次运行时会进行环境检测和配置设置
2. 在macOS上，如果检测到iCloud云盘，会询问是否将备份保存到iCloud
3. 备份文件命名格式：`Rime_[名称]_YYYYMMDD_HHMMSS`
4. `clean` 会列出所有备份并接受序号/区间（如 `3-6`）/关键字（如 `latest`），选中的备份会被移动到 `备份目录/.rimebak_trash`；可通过 `./rimebak.sh undo` 回滚
5. 自带 `scripts/rimebak_onboarding.sh` 引导流程，适合新手；也可在 `~/.config/rime_backup/excludes.txt` 添加排除规则（每行一个模式，使用 `!pattern` 取消默认排除）

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
