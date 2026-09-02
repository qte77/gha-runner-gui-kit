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
- `.github/workflows/yappy-dictation-probe.yml`: dictation-only probe against
  Yappy (virtual audio loopback + synthesized speech + push-to-talk hotkey
  trigger). **Unverified**, and its account-free premise is now known wrong
  — see file header.
- `.github/workflows/yappy-google-login-probe.yml`: step 1 of scripting
  Yappy's mandatory Google sign-in gate — clicks "Sign in with Google" and
  screenshots the result, no credentials yet. **Unverified** — not yet run.
- `.env.example`: template for local secrets (`GMAIL_PW`), values never
  committed.
- `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `LICENSE` (Apache-2.0).

### Changed

- `.github/workflows/example.yml`: added a descriptive `User-Agent` header to
  the release-URL `curl` call, per `yappy.biz/agents.md`'s explicit ask of
  automated clients.
- `.gitignore`: added `.env*` (with `!.env.example` exempted), `*.swp`, and
  `.tmp-artifacts/` — `.env` (holding `GMAIL_PW`) was untracked but not
  ignored, one `git add -A` away from landing in history.

### Fixed

- Corrected a wrong claim (mine, sourced from yappy.biz's own docs) that
  Yappy's core dictation feature needs no account. Running `example.yml`
  and inspecting the actual screenshots showed a mandatory "Sign in with
  Google" gate on first launch — the docs don't match the shipped app.
