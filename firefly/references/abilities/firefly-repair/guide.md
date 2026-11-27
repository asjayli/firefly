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

1. Run `repair` with the absolute command for the managed installation named by the user.
   If that command cannot run, use `bash "<skill-root>/scripts/manage.sh" repair --skill-dir "<absolute-managed-directory>"` from a complete source bundle. The target's receipt and baseline supply the files to restore.
2. Recheck the same managed target with `doctor` and report the results and backups.

## Outputs

- What was repaired, what was backed up, and what was left as it was.

## Handoffs

- The reply returns to the requester; no other skill is entered from here.

## Stop and escalate

- The target receipt or baseline is missing or invalid and there is no complete source bundle available for reinstall. Owner: the requester.

## Boundaries

- This skill repairs firefly-managed assets only; it does not touch project source files.
