# Agent Instructions

Light orchestration notes for AI agents working on this repo — a single composite
GitHub Action, not a multi-agent pipeline. For usage, see [README.md](README.md).
For dev workflow, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Conventions

- One script per OS under `scripts/` (`macos.sh`, `windows.ps1`, `linux.sh`), each
  mirroring the same six-step shape: install → launch by path → settle → screenshot
  → best-effort interact (allowed to fail) → screenshot.
- `action.yml` branches on `runner.os`; never merge the three scripts into one.
- Never claim an OS path is "verified" unless it has actually been run against a
  real target in a real workflow run this session — mark it `UNVERIFIED` in a
  comment otherwise (see `windows.ps1` / `linux.sh` headers).
- Launch apps **by full path**, never by OS-level name lookup (e.g. never
  `open -a NAME` on macOS) — a freshly-installed app isn't registered with
  Launch Services yet and name lookup silently fails.

## Escalate when

- A change would make an `UNVERIFIED` script's status claim inaccurate in either
  direction (marking something verified without a real test run, or vice versa).
- Required information about a target platform's install mechanics is missing.
