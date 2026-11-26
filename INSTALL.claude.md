# firefly For Claude

firefly supports a Claude installation path that mirrors the firefly skill layout used on Codex while staying compatible with Claude's skill and plugin structure. As of 0.2.0 firefly ships every workflow skill itself; superpowers is not a prerequisite and no superpowers skill is installed, overlaid or modified.

## Prerequisites

- `node` and `npm` must be available; the installer always installs OpenSpec
  `1.6.0` (`npm install -g @fission-ai/openspec@1.6.0`), replacing any local
  version
- ripgrep (`rg`) is optional: `firefly tasks` uses it to accelerate task
  scanning and falls back to `grep` when absent

No other upstream is required.

## Managed Assets

The Claude installer manages:

- 31 skill directories under `~/.claude/skills/`:
  - the controller `firefly` and the 24 `firefly-*` capability skills
  - the four OpenSpec support skills: `openspec-explore`, `openspec-propose`,
    `openspec-apply-change`, `openspec-archive-change`
  - the helper skills `mermaid-diagram-specialist` (firefly-original) and
    `playwright-interactive` (vendored, Apache-2.0, © Microsoft Corporation;
    see its `LICENSE.txt` / `NOTICE.txt`)
- the `opsx` command set under `~/.claude/commands/opsx`
- `~/.claude/firefly/references/` — the shared handoff contract and other
  cross-skill reference files every skill cites instead of restating
- runtime scripts under `~/.claude/firefly/bin/` — the `firefly` command
  dispatcher, the shared install/doctor libraries (`firefly-install.sh`,
  `firefly-doctor.sh`, `firefly-common.sh`), the platform doctor
  (`doctor-claude.sh`), `bootstrap-project.sh`, `list-change-tasks.sh`,
  `firefly-diagram.sh`, `firefly-snapshot.sh`, `firefly-record.sh`,
  `review-package`, `task-brief`, `sdd-workspace`,
  `validate-openspec-cn.mjs`, `firefly-upstream.sh` and `firefly-retired.sh`
- the global command `~/.local/bin/firefly` — a platform-neutral command that
  dispatches to installed firefly runtimes
- the source mirror `~/.claude/firefly/` — `assets/`, `scripts/` and
  `manifests/` mirrored by install so global doctor/repair can diff installed
  assets against firefly-owned copies from any directory
- firefly-managed overrides for the upstream OpenSpec npm package internals
  (`config-prompts.js`, `propose.js`)

Current behavior of the Claude firefly layer:

- keeps the same firefly command surface as Codex
- routes every commissioning entry through the same firefly skill boundaries
- installs the support skills those firefly commands depend on

## Install

Tell Claude:

```text
Clone https://github.com/asjayli/Forgevia and run bash scripts/install-claude.sh from the repository root.
```

Or run it directly yourself:

```bash
git clone https://github.com/asjayli/Forgevia.git
cd firefly
bash scripts/install-claude.sh
```

## Managed State

After installation:

- the 31 firefly-managed skill directories exist under `~/.claude/skills/`
- `~/.claude/commands/opsx` exists
- `~/.claude/firefly/references/` and the runtime scripts are in place
- Claude can discover and use the firefly command set globally
- `firefly` is available on PATH through `~/.local/bin/firefly`
- project bootstrap can initialize OpenSpec with `--tools codex,claude` when
  the repository should support both firefly clients

### Symbolic Links

You may use symbolic links to place `~/.claude` or any managed subdirectory on another volume. firefly follows those links and synchronizes the resolved target without replacing the user-defined link; `doctor --repair` follows the same behavior.

The installer replaces only its marked firefly global command. It refuses to
replace another command or a link owned by the user or another installation.

### OpenSpec Override Version Note

firefly's OpenSpec override files are snapshots taken against OpenSpec `1.6.0` (recorded in `manifests/claude.json` as `overrideTargetVersion`). The installer and doctor refuse to overlay them onto a different upstream version, to avoid silently downgrading upstream behavior. When OpenSpec advances, update the override snapshot and the fixed version together.

## Upgrading From 0.1.0

- Re-run the installer; it performs the whole migration.
- The installer and `firefly repair` move the assets left by firefly 0.1.0 (old
  skill directories and the six superpowers overlays), hash-checked, into
  `~/.claude/firefly/retired/<timestamp>/` backups — nothing is deleted.
- After the old overlays are moved away, reinstall or update superpowers to
  restore the upstream superpowers skills.
- The CLI subcommand `firefly draw` is renamed to `firefly diagram`.

## Verify Managed State

```bash
./scripts/doctor-claude.sh
```

Reports `OK`, `MISS`, or `DRIFT` for each managed asset. Run with `--repair` to restore drifted or missing assets:

```bash
./scripts/doctor-claude.sh --repair
```

## Notes

- This is a Claude-specific install path and does not modify `~/.codex`.
