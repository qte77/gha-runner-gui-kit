# gha-runner-gui-kit

A composite GitHub Action: download and launch a GUI app on a runner,
best-effort script an interaction with it, and capture before/after
screenshots as an artifact. The artifact is the deliverable — a successful
scripted interaction is a bonus, not a requirement, since you generally
can't know a third-party app's UI tree in advance.

Extracted from a real probe against a native macOS app, generalized into a
reusable action.

## Status per OS

| OS | Status |
|---|---|
| macOS | **Verified** — proven against a real notarized DMG on `macos-14` |
| Windows | Designed, **not tested** against a real target. No confirmed consumer yet. |
| Linux | Designed, **not tested** against a real target. No confirmed consumer yet. |

Windows and Linux mirror the macOS script's shape (install → launch by path
→ settle → screenshot → best-effort interact → screenshot → done) but have
not been run for real. Treat them as a starting point, not a guarantee —
run against your actual target and fix what breaks.

## Usage

```yaml
- uses: qte77/gha-runner-gui-kit@main
  with:
    download-url: https://example.com/app.dmg
    install-type: dmg          # dmg|zip|pkg (macOS), exe|zip (Windows), appimage|deb|tar (Linux)
    launch-target: ''          # not needed for macOS dmg -- the .app is discovered automatically
    interact-script: ''        # optional, best-effort, allowed to fail
    settle-seconds: '5'
- uses: actions/upload-artifact@v4   # already done internally, screenshots land in
                                       # `gui-probe-screenshots-<os>`
```

See [`.github/workflows/example.yml`](.github/workflows/example.yml) for a
working end-to-end example (macOS). It already installs and launches
[Yappy](https://yappy.biz/), a macOS dictation app, as its verified demo
target. Yappy publishes no Terms of Service; its only agent policy
([`agents.md`](https://yappy.biz/agents.md)) covers its website API, not the
desktop app.

**Confirmed by running `example.yml`'s screenshots**, not by Yappy's docs
(which claim otherwise): Yappy v0.4.22's real first launch is a mandatory
"Sign in with Google" gate, no skip option. A third-party app's UI can't be
known in advance — trust a screenshot from a real run over marketing copy.

[`.github/workflows/yappy-google-login-probe.yml`](.github/workflows/yappy-google-login-probe.yml)
is the login step. **Clicking "Sign in with Google" is confirmed working**
(the button has no accessible name — `button 1 of window 1`, not
`button "Sign in with Google"`). **Past the click is likely not
automatable on GitHub-hosted macOS runners at all**: Yappy's embedded
WebKit auth view finishes loading successfully then goes invisible ~6-7s
later with no error logged; a tight poll ruled out "hides too fast to
catch"; the runner's own system log shows `RunningBoard` process-role
messages consistent with this session type never promoting the resulting
window to visible. See the file header for full evidence. If Google login
needs to happen for real, the remaining options are a self-hosted runner
(a real, normally-logged-in Mac where a human signs in once and the
session persists) or capturing Yappy's post-login persisted state
elsewhere and restoring it into each run — neither attempted. No
credentials have been typed anywhere in this process.

[`.github/workflows/yappy-dictation-probe.yml`](.github/workflows/yappy-dictation-probe.yml)
covers the post-login dictation step — virtual audio loopback, synthesized
speech, Yappy's documented hands-free double-tap hotkey — but its
account-free premise turned out to be wrong (see above); it needs the login
flow folded in ahead of it before it can run meaningfully. **UNVERIFIED**.

## Inputs

| Input | Required | Default | Notes |
|---|---|---|---|
| `download-url` | yes | — | URL to the installer/app archive |
| `install-type` | no | `dmg` | Platform-specific installer kind |
| `launch-target` | no | `''` | Executable name/path; not needed for macOS `dmg` |
| `interact-script` | no | `''` | AppleScript (macOS) / PowerShell (Windows) / shell one-liner (Linux). Allowed to fail. |
| `settle-seconds` | no | `5` | Wait after launch before the first screenshot |

## Why not just one universal script

The install/launch mechanics are genuinely different per OS (DMG mounting
vs. `Expand-Archive` vs. AppImage), and so is screenshot capture
(`screencapture` vs. `System.Drawing` vs. `scrot`+`Xvfb`). The interface
(inputs/outputs, the six-step shape) is what's shared; `action.yml` branches
on `runner.os` to the matching script rather than trying to force one
script to cover three platforms.
