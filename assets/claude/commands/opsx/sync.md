---
name: "OPSX: Sync"
description: Sync delta specs from a change to main specs
category: Workflow
tags: [workflow, specs, experimental]
---

Sync delta specs from a change to main specs.

## Review ownership

Syncing delta specs to main specs is done through `firefly docs` (design position 23). It builds the sync plan, has a reviewer who is not the author review the plan and the result, applies the plan, and validates the result. When firefly docs is not installed, use OpenSpec's own spec-sync skill. This command does no review itself.
