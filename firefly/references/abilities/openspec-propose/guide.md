# OpenSpec proposal guide

Use this reference from [Firefly propose](../firefly-propose/guide.md). It provides the OpenSpec commands for creating the empty change and reading artifact instructions. Firefly propose owns artifact authorship, validation, planning and the ready decision.

## Create the change

From the Firefly project's root, create a repo-local change with the name selected by Firefly propose.

```bash
"<skill-root>/scripts/firefly.sh" new "<name>"
"<skill-root>/scripts/firefly.sh" status "<name>" --json
```

Confirm the reported `schemaName` is `spec-driven` and the `changeRoot` is the project's `openspec/changes/<name>`. If the layout differs, stop and report the unsupported planning location. If the change already exists, return its status to the caller's resumption step.

Return after scaffolding so the caller can record the mandate before writing artifacts.

## Read artifact instructions

When the caller is ready to write an artifact, read its status and instructions.

```bash
"<skill-root>/scripts/firefly.sh" spec instructions <artifact-id> --change "<name>" --json
```

Use the template, structured output path and dependency files as inputs. Apply project context and rules as constraints. Follow the caller's stage order and the command routing in Firefly's entry guide. The planning handoff owns `tasks.md`, and the caller runs Firefly's strict validation with its Chinese requirement support.
