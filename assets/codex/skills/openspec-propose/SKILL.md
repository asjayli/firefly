---
name: openspec-propose
description: Propose a new change with all artifacts generated in one step. Use when the user wants to quickly describe what they want to build and get a complete proposal with design, specs, and tasks ready for implementation.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.6.0"
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

After the ready decision, implementation runs through firefly Implement.

---

**Store selection:** If the user names a store (a store is a standalone OpenSpec repo registered on this machine) or the work lives in one, run `openspec store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `openspec/` root.

**Input**: The user's request should include a change name (kebab-case) OR a description of what they want to build.

## Review ownership

Planning artifacts are judged by the joint ready decision in firefly propose (design position 04). This skill creates the change and validates it; it does not review planning packages and does not report a change as ready to implement. Invoked outside firefly, report the created change as unreviewed.

**Steps**

1. **If no clear input provided, ask what they want to build**

   Ask the user (open-ended, no preset options):
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   openspec new change "<name>"
   ```
   This creates a scaffolded change in the planning home resolved by the CLI with `.openspec.yaml`.

3. **Get the artifact build order**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context. Use these instead of assuming repo-local paths.

4. **Create artifacts in sequence until apply-ready**

   Track progress through the artifacts with the client's available planning mechanism.

   Loop through artifacts in dependency order (artifacts with no pending dependencies first):

   a. **For each artifact that is `ready` (dependencies satisfied)**:
      - Get instructions:
        ```bash
        openspec instructions <artifact-id> --change "<name>" --json
        ```
      - The instructions JSON includes:
        - `context`: Project background (constraints for you - do NOT include in output)
        - `rules`: Artifact-specific rules (constraints for you - do NOT include in output)
        - `template`: The structure to use for your output file
        - `instruction`: Schema-specific guidance for this artifact type
        - `resolvedOutputPath`: Resolved path or pattern to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure and write it to `resolvedOutputPath`
      - Apply `context` and `rules` as constraints - but do NOT copy them into the file
      - Validate the current planning package. If validation fails, repair only the matching planning artifact type and rerun the same validation. Continue only after that planning validation passes.
      - Run the producer self-critique on the current planning package: (1) every acceptance criterion is falsifiable; (2) no task group bundles two distinct delivery units; (3) dependency edges are acyclic; (4) every requirement has a test or verification path; (5) no undeclared external side effects; (6) nothing exceeds the user-authorized scope; (7) no `TBD`, `TODO`, vague placeholders, or undefined interfaces. Repair the findings inline against the matching artifact. This self-critique only reduces obvious problems; it does not replace the joint ready decision in firefly propose.
      - Show brief progress: "Created <artifact-id>"

   b. **Continue until all `applyRequires` artifacts are complete**
      - After creating each artifact, re-run `openspec status --change "<name>" --json`
      - Check if every artifact ID in `applyRequires` has `status: "done"` in the artifacts array
      - Stop when all `applyRequires` artifacts are done

   c. **If an artifact requires user input** (unclear context):
      - Infer reasonable details from the objective, dependencies, and repository evidence
      - If multiple materially different outcomes remain, return to the user with evidence and a recommended default

5. **Run final strict validation**

   After all apply-required artifacts are complete, run `openspec validate "<name>" --strict --no-interactive` for the complete change, preserving `--store <id>` when applicable. If strict validation fails, repair the indicated proposal, design, specs, or tasks and rerun strict validation.

6. **Show final status**
   ```bash
   openspec status --change "<name>"
   ```

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- State that the standalone proposal reached its apply-ready terminal condition.
- Next command: `firefly implement <name>`
- Do not describe this normal terminal condition as a stop, interruption, or lack of authorization. Do not ask whether to proceed; the exact next command is sufficient.

When invoked as a phase of an already-authorized complete firefly delivery, return the resolved change name to the controller instead of emitting this standalone completion summary. The controller continues directly into implementation.

**Artifact Creation Guidelines**

- Follow the `instruction` field from `openspec instructions` for each artifact type
- The schema defines what each artifact should contain - follow it
- Read dependency artifacts for context before creating new ones
- Use `template` as the structure for your output file - fill in its sections
- **IMPORTANT**: `context` and `rules` are constraints for YOU, not content for the file
  - Do NOT copy `<context>`, `<rules>`, `<project_context>` blocks into the artifact
  - These guide what you write, but should never appear in the output

**Guardrails**
- Create ALL artifacts needed for implementation (as defined by schema's `apply.requires`)
- Always read dependency artifacts before creating a new one
- If context is critically unclear, return to the user; ordinary assumptions are not a confirmation gate
- If a change with that name already exists, inspect its objective and status; continue it when it is the unique match, otherwise return to the user for the substantive identity conflict
- Verify each artifact file exists after writing before proceeding to next
- Proposal completion does not authorize implementation, commit, sync, archive, push, merge, or release
