# Third-Party Notices

firefly redistributes or layers managed overrides on the following third-party
components. Each component retains its own license; the root `LICENSE`
(MIT) applies to firefly's original work only and does not replace or
remove any third-party license or notice.

## Redistributed (vendored) components

### playwright-interactive

- **Source:** vendored skill assets derived from Microsoft's
  [playwright-cli](https://github.com/microsoft/playwright-cli) repository.
- **License:** Apache License 2.0 — Copyright (c) Microsoft Corporation.
- **Location:** `assets/codex/skills/playwright-interactive/` and
  `assets/claude/skills/playwright-interactive/`.
- **Notices:** the upstream `LICENSE.txt` and `NOTICE.txt` are retained
  unmodified inside each vendored directory.
- **Modifications:** as recorded in the vendored `NOTICE.txt` — repackaged
  the Playwright icon assets for a `js_repl`-focused skill and wrote new
  skill instructions for persistent browser debugging. firefly redistributes
  the skill without further modification.

## Upstream dependencies with firefly-managed overrides

firefly does not vendor these components; users install them from upstream,
and firefly layers managed override files on top (see `manifests/codex.json`
and `manifests/claude.json`).

### OpenSpec (`@fission-ai/openspec`)

- **Source:** https://www.npmjs.com/package/@fission-ai/openspec
- **License:** MIT.
- **Baseline:** pinned to `1.6.0` (`overrideTargetVersion` in both manifests).
- **Modifications:** firefly installs managed override files
  (`assets/openspec/dist/core/config-prompts.js` and
  `assets/openspec/dist/core/templates/workflows/propose.js`) over the
  upstream installation. Installers protectively skip the override when the
  installed OpenSpec version does not match `1.6.0`.

### superpowers (`obra/superpowers`)

- **Source:** https://github.com/obra/superpowers
- **License:** MIT.
- **Derivation:** the firefly skills `firefly-draw`, `firefly-tasks`,
  `firefly-implement`, `firefly-context`, `firefly-tdd` and `firefly-review`
  were evolved from the corresponding superpowers overlay skills
  (brainstorming, writing-plans, subagent-driven-development,
  executing-plans, test-driven-development). The words in the firefly skills
  are firefly's own, written or rewritten, not copied. firefly 0.2.0 no
  longer installs or maintains any superpowers overlay.

### OpenSpec spec-sync

- **Source:** the `openspec-sync-specs` skill of the OpenSpec distribution.
- **License:** MIT.
- **Derivation:** the spec-sync mechanism of `firefly-docs`
  (`references/spec-sync.md`) takes its mechanism from that skill; the text is
  firefly's own.

## Runtime tools (user-installed, not redistributed)

### mermaid-cli (`mmdc`)

- **Source:** https://github.com/mermaid-js/mermaid-cli
- **License:** MIT.
- **Use:** runtime rendering dependency of the `firefly-draw` skill.

### ripgrep (`rg`)

- **Source:** https://github.com/BurntSushi/ripgrep
- **License:** MIT OR Unlicense.
- **Use:** optional task-scanning accelerator for `firefly-tasks`; falls back
  to `grep` when absent.
