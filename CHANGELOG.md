# Changelog

All notable user-facing changes are documented here. The format follows Keep a Changelog.

## [Unreleased]

### Added

- Restore the v3.0.0 sources that were previously only present locally: the main `rimebak.sh` wrapper plus the `lib/` module directory (core, detect, tui, ops, git_provider, doctor, setup, main).
- Add `rimebak doctor` diagnostics and `rimebak setup` interactive initialization to the documented feature set.
- Add contribution, security, issue-form, CODEOWNERS and license documentation.

### Changed

- Homebrew formula and `install.sh` now install the `lib/` modules alongside the main script.

## [Initial release]

- Initial public repository state.
