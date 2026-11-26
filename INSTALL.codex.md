# firefly For Codex

firefly installs an opinionated Codex workflow around OpenSpec and its own
managed skill set. As of 0.2.0 firefly ships every workflow skill itself;
superpowers is not a prerequisite and no superpowers skill is installed,
overlaid or modified.

This repository is GitHub-first. The Codex path assumes:

- `node` and `npm` are available; the installer always installs OpenSpec
  `1.6.0`, replacing any local version
- firefly ships and manages its own curated copies of the workflow files it owns
- `~/.codex` is the primary managed global target

Claude has a separate install path documented in `INSTALL.claude.md`.

## Prerequisites

- `node` and `npm` must be available; the installer always installs OpenSpec
  `1.6.0` (`npm install -g @fission-ai/openspec@1.6.0`), replacing any local
  version
- ripgrep (`rg`) is optional: `firefly tasks` uses it to accelerate task
  scanning and falls back to `grep` when absent

No other upstream is required.

## Install

```bash
git clone https://github.com/asjayli/Forgevia.git
cd firefly
bash scripts/install-codex.sh
```

## Managed Assets

After installation the Codex installer manages:

- 31 skill directories under `~/.codex/skills/`:
  - the controller `firefly` and the 24 `firefly-*` capability skills
  - the four OpenSpec support skills: `openspec-explore`, `openspec-propose`,
    `openspec-apply-change`, `openspec-archive-change`
  - the helper skills `mermaid-diagram-specialist` (firefly-original) and
    `playwright-interactive` (vendored, Apache-2.0, © Microsoft Corporation;
    see its `LICENSE.txt` / `NOTICE.txt`)
- `~/.codex/firefly/references/` — the shared handoff contract and other
  cross-skill reference files every skill cites instead of restating
- runtime scripts under `~/.codex/firefly/bin/` — the `firefly` command
  dispatcher, the shared install/doctor libraries (`firefly-install.sh`,
  `firefly-doctor.sh`, `firefly-common.sh`), the platform doctor
  (`doctor-codex.sh`), `bootstrap-project.sh`, `list-change-tasks.sh`,
  `firefly-diagram.sh`, `firefly-snapshot.sh`, `firefly-record.sh`,
  `review-package`, `task-brief`, `sdd-workspace`,
  `validate-openspec-cn.mjs`, `firefly-upstream.sh` and `firefly-retired.sh`
- the global command `~/.local/bin/firefly` — a platform-neutral command that
  dispatches to installed firefly runtimes
- the source mirror `~/.codex/firefly/` — `assets/`, `scripts/` and
  `manifests/` mirrored by install so global doctor/repair can diff installed
  assets against firefly-owned copies from any directory
- firefly-managed overrides for the upstream OpenSpec npm package internals
  (`config-prompts.js`, `propose.js`)

## Managed State

After installation:

- `openspec` is available on PATH
- `firefly` is available on PATH through `~/.local/bin/firefly`
- the 31 firefly-managed skill directories are installed under `~/.codex/skills`
- firefly-managed OpenSpec overrides are applied to the installed OpenSpec package

### Symbolic Links

You may use symbolic links to place `~/.codex` or any managed subdirectory on another volume. firefly follows those links and synchronizes the resolved target without replacing the user-defined link; `doctor --repair` follows the same behavior.

The installer replaces only its marked firefly global command. It refuses to
replace another command or a link owned by the user or another installation.

### OpenSpec Override Version Note

firefly's OpenSpec override files are snapshots taken against OpenSpec `1.6.0` (recorded in `manifests/codex.json` as `overrideTargetVersion`). The installer and doctor refuse to overlay them onto a different upstream version, to avoid silently downgrading upstream behavior. When OpenSpec advances, update the override snapshot and the fixed version together.

## Upgrading From 0.1.0

- Re-run the installer; it performs the whole migration.
- The installer and `firefly repair` move the assets left by firefly 0.1.0 (old
  skill directories and the six superpowers overlays), hash-checked, into
  `~/.codex/firefly/retired/<timestamp>/` backups — nothing is deleted.
- After the old overlays are moved away, reinstall or update superpowers to
  restore the upstream superpowers skills.
- The CLI subcommand `firefly draw` is renamed to `firefly diagram`.

## Verify Managed State

```bash
./scripts/doctor-codex.sh
```

Reports `OK`, `MISS`, or `DRIFT` for each managed asset. Run with `--repair` to restore drifted or missing assets:

```bash
./scripts/doctor-codex.sh --repair
```

## Bootstrap A Project

```bash
./scripts/bootstrap-project.sh --tools codex /path/to/project
```

Checks whether OpenSpec is already initialized and runs `openspec init` only when missing. It does not take ownership of project source files.

## Notes

- This is a Codex-specific install path and does not modify `~/.claude`.
