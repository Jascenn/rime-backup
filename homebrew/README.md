# Homebrew Tap for RimeBak

RimeBak 的 Homebrew 安装仓库。

## 安装方法

```bash
brew tap Jascenn/rimebak
brew install rimebak
```

## 更新

```bash
brew upgrade rimebak
```

## 卸载

```bash
brew uninstall rimebak
brew untap Jascenn/rimebak
```

## Formula 维护

更新 Formula 时需要：

1. 在 rime-backup 仓库创建新 Release (如 v2.1.0)
2. 获取 tarball 的 sha256: `curl -sL https://github.com/Jascenn/rime-backup/archive/refs/tags/v2.1.0.tar.gz | shasum -a 256`
3. 更新 `Formula/rimebak.rb` 中的 `url` 和 `sha256`
