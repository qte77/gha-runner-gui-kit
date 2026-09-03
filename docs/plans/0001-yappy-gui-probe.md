# Plan 0001: Yappy GUI probe & macOS runner compatibility

## Goal

Use `gha-runner-gui-kit` (this repo's own composite action) to install and
drive Yappy (a macOS dictation app) end-to-end: install → launch → sign in
with Google → exercise dictation. Along the way, keep the composite action
itself correct as GitHub's macOS runner images move forward.

## Source map (exact files, no re-discovery needed)

| File | Role | Status |
|---|---|---|
| `action.yml` + `scripts/macos.sh` | Composite action core (install → launch → settle → screenshot → best-effort interact → screenshot) | Verified on `macos-14`. NOT re-verified on `macos-26` — see blocker table. |
| `scripts/windows.ps1`, `scripts/linux.sh` | Structural mirrors for the other OSes | Unverified (out of this arc's scope; `scripts/linux.sh` has separate concurrent work happening on branch `fix/linux-xvfb-race-and-blank-render` — not owned by this plan, see Note below) |
| `.github/workflows/example.yml` | Generic demo target, installs Yappy with no interaction | Verified on `macos-14`. Currently pinned back to `macos-14` (see blocker table) |
| `.github/workflows/yappy-google-login-probe.yml` | Scripts the "Sign in with Google" click | Click confirmed working (`click button 1 of window 1`). Everything past the click is **closed as not-automatable on macos-14** (11 dispatches; full evidence in this file's header comment). Retest on `macos-26` was **inconclusive** — see blocker table. |
| `.github/workflows/yappy-dictation-probe.yml` | Post-login dictation exercise (audio loopback + hands-free hotkey) | Written, mechanically sound, but **not runnable** — needs a signed-in Yappy, which isn't reachable per the above |
| `README.md` "Case study: Yappy" section | Human-facing narrative of the whole arc | Up to date as of the Google-login closure; NOT yet updated with the `macos-26` screencapture regression |
| `CHANGELOG.md` | `[Unreleased]` → `Added`/`Changed`/`Fixed`/`Decided` | Up to date as of the Google-login closure; NOT yet updated with the `macos-26` regression |
| `.env.example` / `.gitignore` | Credential hygiene (`GMAIL_PW` template, `.env` never committed) | Done |
| Memory: `yappy_login_arc.md`, `gh_token_env_shadow.md` | Cross-session continuity notes | Up to date as of the Google-login closure |

## What's already shipped (on `main`, don't redo)

- Composite action core, verified on `macos-14` (real notarized DMG).
- `.env`/`.gitignore` credential-hygiene fix.
- Google sign-in button click mechanism solved and documented.
- Google login itself **closed** as out of scope for GitHub-hosted macOS
  runners (structural RunningBoard/session-type limitation, not a script
  bug) — two research passes done, two cheap fixes tried (App Nap,
  `launchctl asuser`), neither changed the result. Not being re-opened
  without genuinely new information.
- Yappy bug-report email drafted (in conversation, not yet saved to a
  file or sent — owner's call).

## NEW blocker found this session, not yet resolved or fully documented

Bumping the three workflows' `runs-on:` from `macos-14` to `macos-26`
(needed eventually — `macos-14` images deprecate 2026-11-02, see
`actions/runner-images#13518`) surfaced an unrelated regression: **a
second `screencapture -x` call within the same job now triggers a system
consent dialog** ("'bash' is requesting to bypass the system private
window picker...") on `macos-26`, with no dialog on the first call and no
dialog at all on `macos-14`. Confirmed via `example.yml`, which has zero
interact-script — so this is NOT Yappy-specific, it breaks the composite
action's "after" screenshot for every consumer on `macos-26`. This also
makes the Yappy-on-`macos-26` login retest inconclusive (we can't see
what actually happened, only the consent dialog).

The `chore/bump-macos-26` branch (pushed to origin, NOT merged) contains
the runner-image bump as originally attempted, before this regression was
understood. It should not be merged as-is.

## Remaining work

| Item | Gate | Done-when |
|---|---|---|
| Mitigate the `macos-26` screencapture consent dialog | agent (research dispatched, result pending) | A working fix is found and verified via a real run showing a clean, dialog-free "after" screenshot on `macos-26` — or the research comes back empty and this is documented as a second closed/structural limitation |
| Decide `macos-14` vs `macos-26` (or both) support strategy | owner | Owner picks one: (a) stay on `macos-14` until closer to the Nov 2026 deadline, (b) support both via separate/parameterized workflows, (c) fully migrate to `macos-26` once the dialog is mitigated |
| `chore/bump-macos-26` branch disposition | owner | Owner decides: merge (if a mitigation lands), close (if staying on `macos-14` for now), or leave open pending the research result |
| Retest Yappy Google login on `macos-26` (real signal, not just a screenshot) | agent, after the above two items resolve | A run on `macos-26` with a working screenshot mechanism either shows the Yappy sign-in window (breakthrough — re-open the login arc) or confirms it's still absent (closes the `macos-26` question the same way `macos-14` was closed) |
| Send (or discard) the Yappy bug-report email | owner | Owner sends the drafted email to support@yappy.biz, or decides not to — either way this stops appearing as open |
| Confirm `GH_TOKEN`/`GITHUB_TOKEN` rotation | owner | Owner confirms the two tokens exposed earlier this session (`github_pat_...`, `ghu_...`) have been rotated — cannot be verified from inside a session |

## Note: unrelated concurrent work, not part of this plan

Branch `fix/linux-xvfb-race-and-blank-render` (remote, actively being
pushed to by another process/session during this arc) contains a real fix
to `scripts/linux.sh` (Xvfb-readiness race, blank-capture detection).
That work is **not owned by this plan** and this plan does not track its
completion — whoever is driving it merges or closes it on their own. It's
noted here only so a future reader isn't confused by its existence.
