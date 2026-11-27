---
name: firefly-repair
description: Use when the user explicitly asks firefly to repair missing or drifted firefly-managed assets in the installed skill package.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "01"
---

# firefly Repair

## When to use

- The user explicitly asks firefly to repair the managed installed skill package.

## When not to use

- The user asks only to inspect, not repair: that is `firefly doctor`, which modifies nothing.

## Mandate

**Fixed end.** Every `MISS` and `DRIFT` the doctor reported is repaired from the firefly-owned copies, with a backup preserved before each replacement, or the repair stops under "Stop and escalate".

**Permitted effects.**

- Run the firefly doctor flow with repair enabled.
- Repair `MISS` and `DRIFT` states from firefly-owned copies.
- Preserve backups before replacement.

**Not granted.**

- Repairing OpenSpec overrides when the upstream OpenSpec version differs from the override snapshot version.

## Inputs

- The doctor report, when one is at hand; otherwise the repair run produces its own.

## Procedure

### Run the repair

1. Run the installed runtime's `repair` command: `"<skill-root>/scripts/firefly.sh" repair`.
   If the runtime is missing or cannot start, use a complete Firefly source package: `bash firefly/scripts/manage.sh repair --skills-dir <absolute-skill-parent>` from its repository root.
2. It refuses to repair OpenSpec overrides when the upstream OpenSpec version differs from the override snapshot version, to avoid downgrading upstream.

## Outputs

- What was repaired, what was backed up, and what was left as it was.

## Handoffs

- The reply returns to the requester; no other skill is entered from here.

## Stop and escalate

- The upstream OpenSpec version differs from the override snapshot version. Owner: the requester.

## Boundaries

- This skill repairs firefly-managed assets only; it does not touch project source files.
