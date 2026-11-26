---
name: firefly-init
description: Use when the user explicitly asks firefly to initialize OpenSpec in the current project or verify whether the current project is ready for the firefly workflow.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "01"
---

# firefly Init

## When to use

- The user explicitly asks firefly to initialize the current project.
- The user asks whether the current project is ready for the firefly workflow.

## When not to use

- No explicit initialization or readiness request: the router and the runtime commands decide their own entry.
- The repository owner has not asked to change the project's OpenSpec initialization state.

## Mandate

**Fixed end.** The project's OpenSpec initialization state is established or confirmed, and the reply reports it. Do not modify project source files beyond OpenSpec's own initialization behavior.

**Permitted effects.**

- Check whether `openspec` is installed and available.
- Check whether the current project already has OpenSpec initialization.
- If missing, invoke firefly's project bootstrap flow to run `openspec init`.
- When preparing a repository for the Claude firefly path, prefer initializing with `--tools codex,claude` so the project can be used consistently from both firefly clients.

**Not granted.**

- Any modification of project source files beyond OpenSpec's own initialization behavior.

## Inputs

- The project directory, when the user names one; otherwise the current directory.

## Procedure

### Run the bootstrap

1. Run the installed runtime script: `bash "$HOME/.claude/firefly/bin/bootstrap-project.sh" [--tools codex,claude] [project_dir]`.
2. It checks whether `openspec` is on PATH and whether the target project already has OpenSpec initialization, then runs `openspec init` only when missing.

## Outputs

- The initialization state it found and what, if anything, it initialized.

## Handoffs

- The reply returns to the requester; no other skill is entered from here.

## Stop and escalate

- `openspec` is not available and installing it is outside this mandate. Owner: the requester.

## Boundaries

- This skill initializes and verifies; it does not author specs, implement or archive anything.
