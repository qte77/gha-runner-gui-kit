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
| macOS | **Verified on `macos-14`** — proven against a real notarized DMG. **`macos-26`: known broken**, see below. |
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

### Case study: Yappy, and the CI ceiling for this action

**Confirmed by running `example.yml`'s screenshots**, not by Yappy's docs
(which claim otherwise): Yappy v0.4.22's real first launch is a mandatory
"Sign in with Google" gate, no skip option. A third-party app's UI can't be
known in advance — trust a screenshot from a real run over marketing copy.

[`.github/workflows/yappy-google-login-probe.yml`](.github/workflows/yappy-google-login-probe.yml)
scripts up to that gate. **Clicking "Sign in with Google" works** (the
button has no accessible name — `click button 1 of window 1`, not
`click button "Sign in with Google"`).

**Decided, closed: Google sign-in itself is out of scope for this action on
GitHub-hosted macOS runners, and not being pursued further here.** This
isn't "still blocked, more work planned" — it's a structural limit of the
runner environment. Evidence (10 dispatches; full detail in the file's
header): Yappy's embedded WebKit auth view finishes loading successfully,
then goes invisible ~6-7s later with no error ever logged; a poll every
0.2s for 6s right after the click never found a window at all, ruling out
"exists but hides too fast to catch"; no crash report exists; the runner's
own system log shows `RunningBoard` process-role messages (`WindowServer`
in role `Background`) consistent with this session type never promoting
the resulting modal to a visible/key state. That's a property of the
runner's session type, not something an AppleScript change can fix.

If a project genuinely needs Yappy signed in for testing, the two paths
are a self-hosted runner (a real, normally-logged-in Mac where a human
signs in once and the session persists across runs) or capturing Yappy's
post-login persisted state elsewhere and restoring it into each ephemeral
run. Neither is implemented here — this repo has no macOS hardware outside
GitHub-hosted runners to build or verify either against. No credentials
have been typed anywhere in this process.

[`.github/workflows/yappy-dictation-probe.yml`](.github/workflows/yappy-dictation-probe.yml)
covers the post-login dictation step — virtual audio loopback, synthesized
speech, Yappy's documented hands-free double-tap hotkey — kept for
reference (its mechanics are still accurate) but **not runnable as-is**:
it needs a signed-in Yappy first, which per the above isn't reachable in
this repo's CI. Treat it as a starting point for whoever solves login via
one of the two paths above, not as a working probe.

### `macos-26` is currently unusable for this action — also closed, not just untested

Bumping the runner image from `macos-14` to `macos-26` (tried on a
since-parked branch, `chore/bump-macos-26`) surfaced a second, unrelated
regression: **a second `screencapture -x` call within the same job now
triggers an unclickable system consent dialog** ("'bash' is requesting to
bypass the system private window picker..."), confirmed via `example.yml`
— which has zero `interact-script` — so this has nothing to do with Yappy;
it breaks this action's "after" screenshot for every consumer on
`macos-26`. `main` itself was never changed to `macos-26`; the bump only
ever existed on that now-parked branch.

This is a known, already-reported, unresolved problem — not something
worth re-investigating from scratch. Apple Developer Forums thread 806451
reports the identical popup blocking GitHub Actions UI tests on macOS 15,
with zero replies. The sanctioned Apple replacement (`ScreenCaptureKit` +
`SCContentSharingPicker`) is itself an interactive system-picker UI —
there is no documented way to satisfy it headlessly, and no fix exists in
`actions/runner-images`. Staying on `macos-14` until closer to its
2026-11-02 deprecation (`actions/runner-images#13518`), or until Apple or
GitHub ships a fix, whichever comes first.

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
