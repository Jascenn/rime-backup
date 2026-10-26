# 贡献指南 Contributing

`RimeBak`：Rime 输入法配置的跨平台备份、恢复与 Git 同步工具。 小改动可以直接提 PR；涉及对外行为、数据结构、发布流程或批量重构时，请先开 Issue 对齐范围。

## 本地验证

```bash
bash -n rimebak.sh
bash -n install.sh
./rimebak.sh --help
```

如果 README 的安装步骤无法照做，请把它当作 bug 提交。不要把“在我机器上能跑”当作验证完成。

## 分支与提交

- 分支名使用 `feat/`、`fix/`、`docs/`、`refactor/`、`chore/` 前缀和 kebab-case 描述。
- `main` 只接受 PR；不要直接推送，也不要 force push 已共享的分支。
- 提交标题使用 Conventional Commits，例如 `fix(cli): preserve backup before overwrite`。
- 一个 PR 只解决一个问题。行为变化、格式化、依赖升级不要混在同一次提交里。
- 默认建议 squash merge，让一个 PR 对应 `main` 上的一条可回溯记录。

## 本项目的安全边界

- 任何清理、覆盖、恢复操作都必须保留可撤销路径；新增破坏性操作时必须提供 `--dry-run` 或等价预览。
- 测试时使用临时目录和脱敏样例，不要读取或提交真实用户输入法配置、iCloud 路径和个人词典。
- 修改备份目录识别、恢复顺序或 Git 同步时，至少验证 macOS、Linux 和 Windows 支持说明是否仍然准确。
- Homebrew formula 与主脚本的版本号必须同步；发布前确认安装、升级和卸载路径没有变化。

## PR 最少要写什么

1. 为什么需要改，关联的 Issue 或具体问题。
2. 改了什么，以及明确没有改什么。
3. 陌生人能照着执行的验证命令和结果。
4. 影响面与回滚方式；涉及页面时附桌面和移动端截图。

## 审查与合并

单人维护时，PR 的价值是给未来的自己留下“当时为什么这样做”。评论建议标注 `【阻塞】`、`【建议】` 或 `【nit】`。安全漏洞不要开公开 Issue，请按 [SECURITY.md](SECURITY.md) 私下报告。

## 范围

本项目主要覆盖：Shell 主程序、平台检测、备份恢复、Git 同步、安装脚本和 Homebrew formula。
