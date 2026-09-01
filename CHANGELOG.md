# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `action.yml` + `scripts/macos.sh`: composite action core — download, install,
  launch by path, screenshot, best-effort scripted interaction, screenshot,
  upload as artifact. macOS path verified against a real notarized DMG.
- `scripts/windows.ps1` + `scripts/linux.sh`: structural mirrors of the macOS
  script for the other two runner OSes. **Unverified** — no confirmed
  consumer yet, not run against a real target.
- `.github/workflows/example.yml`: end-to-end usage example (macOS).
- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `LICENSE` (Apache-2.0).
