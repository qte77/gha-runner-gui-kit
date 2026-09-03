# Handoff 0001: Yappy GUI probe & macOS runner compatibility

Read `docs/plans/0001-yappy-gui-probe.md` first — it has the full source
map and the single remaining-work table. This file is just "how to pick
this up and keep going."

## What shipped

Everything under "What's already shipped" in the plan is on `main`,
pushed, done. Don't re-investigate the Google-login-on-`macos-14`
question — it's closed with 11 dispatches of evidence in
`yappy-google-login-probe.yml`'s own header comment. Read that header
before touching that file again.

## What's next, in order

1. **Check on the `macos-26` screencapture research fork** (dispatched
   this session, result not yet in as of this handoff). If it found a
   fix: apply it, re-run `example.yml` on `macos-26`, confirm the "after"
   screenshot is clean (no consent dialog), *then* re-run
   `yappy-google-login-probe.yml` on `macos-26` for a real (not
   screenshot-blocked) signal on whether Yappy's window issue persists on
   the newer OS. If the research found nothing: document that plainly
   (same tone as the Yappy closure — "structural limitation", not
   "blocked, more work planned") and move to step 2.
2. **Take the `macos-14`/`macos-26` decision to the owner** (one of the
   three options in the plan's table) — don't guess a default here, this
   one genuinely needs a human call given the cost/timeline tradeoff.
3. **Resolve `chore/bump-macos-26`** (merge, close, or leave open)
   according to whatever the owner picked in step 2.
4. Everything else in the remaining-work table is owner-gated
   (send/don't-send the bug report, confirm token rotation) — not
   agent-actionable, just needs a status check next session.

## Where things physically are

- This plan/handoff pair and any related work was authored in an
  **isolated git worktree**, not the main checkout, because another
  process was actively pushing to a differently-named branch
  (`fix/linux-xvfb-race-and-blank-render`) in the shared working
  directory at the time, with uncommitted staged changes mid-flight. Do
  not assume the main checkout's currently-checked-out branch reflects
  this arc — check `git branch`/`git status` fresh each session.
- The branch this work landed on: `work/macos26-followup`, based on
  `origin/main` at the time of branching. Confirm whether it's been
  merged/pushed by the time you read this — if not, that's itself an
  open item.
- `.tmp-artifacts/` (a local, gitignored scratch dir this session used to
  download and inspect ~15 runs' worth of screenshots/logs) was deleted
  at the end of this session. If it's back, it's just scratch space again
  — safe to delete, nothing durable lives there. All real findings are in
  the workflow file headers, README, CHANGELOG, and memory files.

## Watch-outs

- **Don't re-run pure AppleScript/CI-side workarounds on the
  `macos-14` Google-login question.** That path is genuinely exhausted
  (11 dispatches, two research passes). Only revisit it if something
  external changes (a GitHub runner-image update, or Yappy itself
  switching away from an embedded WKWebView).
- **The `macos-26` screencapture dialog is a different problem from the
  Yappy login issue** — don't conflate them. One is Yappy-specific
  (WebKit window visibility); the other is generic to the composite
  action on `macos-26` (screenshot permission), reproducible with zero
  interact-script.
- **Never read `.env`'s contents.** Its only known key, `GMAIL_PW`, was
  never needed for anything actually built this arc (Google login was
  never successfully scripted), and the discipline of not touching it
  should continue.
- **Two GitHub tokens (`GH_TOKEN`, a `github_pat_...`; `GITHUB_TOKEN`, a
  `ghu_...`) were accidentally printed into a session transcript earlier
  in this arc.** The owner was told to rotate both. Don't assume that's
  done — ask if it's relevant to whatever you're doing next.
- **`gh` in this environment needs `env -u GH_TOKEN -u GITHUB_TOKEN`
  prefixed**, because an invalid `GH_TOKEN` env var shadows a valid
  stored keychain login. See memory `gh_token_env_shadow.md`.
- **A brand-new workflow file must exist on the repo's default branch
  before `gh workflow run` can dispatch it at all** — even targeting a
  different `--ref`. Only an *existing* workflow's *content* can be
  iterated on via a non-default branch. This tripped things up once this
  arc; don't relearn it the hard way again.
