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
  Yappy's mandatory Google sign-in gate. Run for real (10 dispatches): the
  click is confirmed working (`button 1 of window 1`, no accessible name).
  Past the click is **likely not automatable on GitHub-hosted macOS
  runners specifically** — Yappy's embedded-WebKit auth webviews finish
  loading successfully then go invisible ~6-7s later with nothing logged
  as an error; a tight 6s poll ruled out "hides too fast to catch"; no
  crash report exists; the runner's own unified log shows RunningBoard
  process-role messages (WindowServer in role `Background`) consistent
  with this session type never promoting the resulting modal/sheet window
  to visible. No credentials typed anywhere. See file header for full
  evidence and the two remaining options (self-hosted runner, or capture
  + restore Yappy's post-login persisted state).
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

### Decided

- **Closing the Yappy Google-login automation attempt as out of scope for
  this action on GitHub-hosted macOS runners.** Not "blocked, more work
  planned" — 11 dispatches of evidence (see
  `yappy-google-login-probe.yml`'s header) point to a structural limit of
  the runner's session type (RunningBoard process-role assignment), not a
  fixable script bug. Also tried, per two web-research leads, and neither
  changed the result: disabling App Nap before launch, and relaunching via
  `launchctl asuser` instead of plain `open`. Remaining paths (a
  self-hosted runner, or capturing and restoring Yappy's post-login state)
  both need macOS hardware this repo doesn't have access to, and aren't
  being pursued here. `yappy-dictation-probe.yml` is kept for reference
  only — not runnable without a signed-in Yappy.
