# Changelog

All notable user-facing changes are documented here. The format follows Keep a Changelog.

## [Unreleased]

## [3.0.1] - 2026-10-27

### Fixed

- `rimebak stats` is now a read-only command instead of silently creating a full backup.
- Unknown commands now exit with status `2` and a clear error instead of creating a backup.
- `rimebak stats` now reports the combined size of the backups it actually found across all scan directories.
- `rimebak stats` now groups counts and sizes by scan directory so the active backup folder is not mixed with historical archives.
- Legacy `Windows-Rime` backups are now included in list and stats.

### Changed

- Named backups now use the explicit `rimebak backup <name> [note]` command.
- `rimebak --help` now lists the actual non-interactive commands.

## [3.0.0]

### Added

- Add contribution, security, issue-form, CODEOWNERS and license documentation.
- Restore the v3.0.0 modular sources and Homebrew module installation.

## [Initial release]

- Initial public repository state.
