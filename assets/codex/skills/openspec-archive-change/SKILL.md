---
name: openspec-archive-change
description: Archive a completed change in the experimental workflow. Use when the user wants to finalize and archive a change after implementation is complete.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.6.0"
---

Archive a completed change in the experimental workflow.

**Store selection:** If the user names a store (a store is a standalone OpenSpec repo registered on this machine) or the work lives in one, run `openspec store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `openspec/` root.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

An explicit archive request authorizes the named change's spec sync and local archive move.

## Review ownership

Spec sync, the archive package, and readiness are judged by firefly archive (25), which uses firefly docs (23) for the sync. This skill performs the archive move it is asked for; it does not review and does not decide readiness.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise infer a uniquely identified change from conversation context or run `openspec list --json` and show only active changes with their schema when available.

   - Auto-select if only one active change exists.
   - If multiple changes are equally plausible and repository or conversation evidence cannot distinguish them, request one substantive selection with the candidate differences and a recommended default.

2. **Check artifact completion status**

   Run `openspec status --change "<name>" --json` to check artifact completion.

   Parse the JSON to understand:
   - `schemaName`: The workflow being used
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context
   - `artifacts`: List of artifacts with their status (`done` or other)

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Include the warning in the archive summary; it is not a confirmation gate by itself

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Include the warning in the archive summary; escalate only if it creates unresolved data-loss or goal-conflict risk

   **If no tasks file exists:** Proceed without task-related warning.

4. **Assess delta spec sync state**

   Use `artifactPaths.specs.existingOutputPaths` from status JSON to check for delta specs. If none exist, proceed without sync.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `<planningHome.root>/openspec/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Build a combined sync plan
   - Sync delta specs through firefly docs when it is installed; otherwise use the OpenSpec spec-sync skill.
   - Validate the sync result for intended content, preservation, and idempotency

5. **Perform the archive**

   Create an `archive` directory under `planningHome.changesDir` if it doesn't exist:
   ```bash
   mkdir -p "<planningHome.changesDir>/archive"
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move `changeRoot` to the archive directory

   ```bash
   mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
   ```

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Whether specs were synced (if applicable)
   - Note about any warnings (incomplete artifacts/tasks)

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs")

All artifacts complete. All tasks complete.
```

**Guardrails**
- Auto-select a uniquely identified change; request selection only for multiple equally plausible candidates
- Use artifact graph (openspec status --json) for completion checking
- Don't block archive on ordinary warnings - record them in the summary
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- Sync delta specs through firefly docs when it is installed; otherwise use the OpenSpec spec-sync skill.
