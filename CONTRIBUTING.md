# Contributing

For agent behavioral rules see [AGENTS.md](AGENTS.md). For usage see [README.md](README.md).

## Scope

A single composite GitHub Action. No application code, no package manager —
just `action.yml` and one script per OS under `scripts/`.

## Testing a change

There's no unit-test harness for shell/PowerShell glue code driving a real
GUI app — the only meaningful test is running the
[example workflow](.github/workflows/example.yml) (or your own) via
`workflow_dispatch` on the runner OS you changed, and reading the uploaded
screenshots. Validate any YAML you touch first:

```bash
python3 -c "import yaml; yaml.safe_load(open('action.yml'))"
```

## Adding a new OS or install-type

Follow the existing six-step shape (install → launch by path → settle →
screenshot → best-effort interact → screenshot) — don't add steps beyond
that shape without a concrete reason. Mark a script `UNVERIFIED` in its
header comment until it has actually run successfully against a real target
in a real workflow run; only remove that marker once it has.

## Conventional Commits

`feat`, `fix`, `docs`, `chore`, `refactor` — optional scope, e.g. `feat(windows): ...`.

## Branches

`feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`. Squash-merge only.

## CHANGELOG

Add an entry under `[Unreleased]` for any user-facing change (new input,
new OS support, behavior change). Skip for typos/formatting.
