# macOS 快速上手

适合第一次使用 RimeBak 的 macOS 用户，按步骤操作即可完成配置备份。

## 1. 准备工作

- macOS 12 及以上（建议保持系统更新）
- 已安装 [Git](https://git-scm.com/download/mac) 和 `rsync`（macOS 自带，无需额外安装）
- 终端 (Terminal.app 或 iTerm2)

## 2. 下载项目

```bash
cd ~/Downloads           # 或者你喜欢的任意目录
git clone git@github.com:Jascenn/rime-backup.git
cd rime-backup
```

> 不熟悉 Git？也可以在 GitHub 页面点击 **Code → Download ZIP**，解压后在 Finder 中右键文件夹选择 “在终端中打开”。

## 3. 运行新手引导脚本

```bash
bash scripts/rimebak_onboarding.sh
```

引导脚本会逐步为你完成下列操作：

1. 检查关键依赖（`bash`、`rsync` 等）
2. 询问是否安装为全局命令（需要输入一次管理员密码）
3. 引导运行 `rimebak setup` 设置备份目录
4. 可选地立即创建第一份备份
5. 展示常用命令与撤销方式

所有操作都有解释，并提供退出选项，不会强制执行。

## 4. 常用命令速查

```bash
rimebak setup         # 重新指定备份目录（若未安装为全局命令，换成 ./rimebak.sh setup）
rimebak               # 创建一次标准备份
rimebak list full     # 查看所有备份和对应路径
rimebak clean         # 交互式选择要删除的备份（支持 1-3、latest 等写法）
rimebak undo          # 撤销最近一次 clean 操作
rimebak open latest   # 用 Finder 打开最新的备份
```

## 5. 备份目录建议

- 默认会提示你选择 iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/`)，这样可以借助云同步
- 也可以选择外接硬盘或本地任意目录，脚本会自动创建
- 如果要更换备份目录，随时运行 `rimebak setup`

## 6. 常见问题

- **Finder 没有自动打开备份？** 确保是在 macOS 终端运行，脚本会调用 `open` 命令
- **想排除一些大文件？** 编辑 `~/.config/rime_backup/excludes.txt`，每行一个模式，例如 `build/`，使用 `!build/` 可以恢复默认行为
- **忘记删除了哪些备份？** 最近一次 `clean` 会记录在 `<备份目录>/.rimebak_trash`，使用 `rimebak undo` 即可恢复

按照以上步骤，你就能在 macOS 上快速完成 Rime 配置的备份和管理。祝使用愉快！
