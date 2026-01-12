# Homebrew Tap for RimeBak

RimeBak 的 Homebrew 安装仓库。

## 🍺 用户安装

```bash
brew tap Jascenn/rimebak
brew install rimebak
```

## 🔧 维护者：创建 Tap 仓库

### 步骤 1：创建 GitHub 仓库

在 GitHub 上创建新仓库，名称必须为 `homebrew-rimebak`。

### 步骤 2：初始化仓库结构

```bash
mkdir homebrew-rimebak && cd homebrew-rimebak
mkdir Formula
git init
```

### 步骤 3：复制 Formula 文件

将 `rime-backup/homebrew/Formula/rimebak.rb` 复制到 `homebrew-rimebak/Formula/rimebak.rb`

### 步骤 4：创建 README

```markdown
# homebrew-rimebak

Homebrew tap for RimeBak.

## Installation

\`\`\`bash
brew tap Jascenn/rimebak
brew install rimebak
\`\`\`

## Update

\`\`\`bash
brew upgrade rimebak
\`\`\`
```

### 步骤 5：推送到 GitHub

```bash
git add .
git commit -m "Initial commit: RimeBak formula"
git remote add origin git@github.com:Jascenn/homebrew-rimebak.git
git push -u origin main
```

## 📋 更新 Formula

当发布新版本时：

1. 在 rime-backup 创建新 Release tag
2. 获取 tarball sha256:

   ```bash
   curl -sL https://github.com/Jascenn/rime-backup/archive/refs/tags/vX.X.X.tar.gz | shasum -a 256
   ```

3. 更新 Formula 中的 `url` 和 `sha256`
4. 提交并推送到 homebrew-rimebak 仓库
