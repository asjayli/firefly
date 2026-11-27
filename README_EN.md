<div align="center">

# firefly

### A standalone agent skill

[中文](README.md) | English

</div>

**Current version: 0.2.0** ([CHANGELOG](CHANGELOG.md)) · License: [MIT](LICENSE) · [Third-party notices](THIRD_PARTY_NOTICES.md)

firefly turns each user mandate into an acceptable deliverable: an investigation returns a supported explanation, a proposal states what would be built, an implementation delivers a verified change, and a review returns an independent judgment. Not every mandate ends in a code change.

## Scope

### What firefly does

- Turns a mandate into an acceptable deliverable: four commissioning entries (find out why / propose without implementing / implement the approved design / review this candidate), each with a fixed terminal condition and evidence requirements.
- Treats subcommands as the authorization boundary: a named entry such as `firefly think` or `firefly implement <change>` enters that capability's skill directly; the command name fixes the terminal condition and grants no unrelated effects — an investigation is never upgraded to edits.
- Provides 23 skills plus a set of runtime subcommands (`init` / `doctor` / `repair` / `validate` / `tasks` / `diagram` / `snapshot` / `record`), and manages installation, health checks and repair of the global managed assets.

### What firefly does not do

- Does not take over your project source: it writes only specs, task records and verification records within the command boundary, and never silently overlays project files.
- Does not make trade-offs on your behalf: options with different consequences go back to the user and the owner; a worker cannot widen the mandate or approve its own candidate.
- Does not build a second scheduler: resumption reuses the existing specs, `tasks.md`, Git and verification records — no state kernel, no cross-process dispatcher.
- Does not auto-trigger: it works only when the user explicitly asks for firefly or names a subcommand; a coding request alone is not a trigger.

## Installation

Install the skill and invoke Firefly once in your agent host.

```bash
npx skills@latest add asjayli/firefly
```

On the first workflow invocation that allows writes, the agent installs `~/.local/bin/firefly` and its repair baseline from the skill bundle, then continues the requested task. The managed runtime lives under `${XDG_DATA_HOME:-$HOME/.local/share}/firefly/runtime/firefly`. Firefly reuses any healthy managed command at the destination. Help and read-only queries run from the bundle without starting installation. If the host restricts writes to the user directory, run `bash <skill-directory>/scripts/manage.sh bootstrap` in a terminal. Add the command directory to `PATH` or run `~/.local/bin/firefly doctor` directly.

### Manual managed installation

To choose the skill and command locations, run from a separate source checkout:

```bash
bash firefly/scripts/manage.sh install --skills-dir /path/to/skills --bin-dir "$HOME/.local/bin"
```

Set `--skills-dir` to the skill directory's parent, as configured in your host. Omit `--bin-dir` to use `scripts/firefly.sh` directly from the skill directory. Run `firefly doctor` to check the installation and `firefly repair` to restore it from its own baseline. Replaced assets are backed up beside the destination under `.firefly-backup.*/previous`.

The skill discovery path can be a symlink. The CLI uses that stable path. After moving `references` or `scripts` and linking it back into the skill, rerun the installation with `--references-dir` or `--scripts-dir` to register the corresponding target. Installation preserves the links and repairs use their registered targets.

If the runtime scripts are missing, run recovery from a complete Firefly source package:

```bash
bash firefly/scripts/manage.sh repair --skills-dir /path/to/skills
```

Updates and uninstalls through `npx skills` affect the host's skill directory. The global runtime remains installed. To update the first-use runtime, run the native installer from the new source with `--skills-dir` set to `${XDG_DATA_HOME:-$HOME/.local/share}/firefly/runtime` and `--bin-dir` set to the current command directory. To uninstall that runtime, remove its command symlink and managed runtime directory. For a manual installation with custom paths, use its original locations.

## Skills

The table lists firefly's 23 skill subcommands, matching the controller's registry one to one. "Design position" is the number of the engineering judgment in the design document (17 simplification merges into `firefly review`, 21 pipeline gates into `firefly guard`, 22 legacy retirement into `firefly archive`).

| Subcommand | Position | One-line duty | Entry condition |
|---|---|---|---|
| `firefly next` | 01 controller | Propose the next 3–5 steps read-only, each with evidence source and completion standard | When you want to know what is next |
| `firefly think` | 02 clarify | Clarify a requirement one question at a time before any proposal; minutes land under `openspec/think/` | The user must choose between options with different consequences |
| `firefly draw` | 03 concept | Settle the first user behavior worth delivering via a one-page comparison, a sequence diagram or a disposable probe | Questions cannot settle it, or request/job/file lifetimes are unclear |
| `firefly propose` | 04 spec | Turn a requirement into an OpenSpec change and take both packages through the joint ready decision | Part of the full delivery path |
| `firefly bounds` | 05 quality bar | Agree quality constraints beside the scenarios before implementation; run affected checks when a review dispatches them | The change touches service objectives, compatibility or data boundaries |
| `firefly tasks` | 06 tasks | Divide a ready spec into independently verifiable tasks with a two-way scenario map; the query entry lists unfinished tasks read-only | Part of the full delivery path |
| `firefly implement` | 07 implement | Deliver one change that passed its ready decision: one implementer per task group, fixed candidate snapshots, integrated delivery | Part of the full delivery path |
| `firefly source` | 08 sources | Record what a third-party dependency promises at the installed version and what the environment actually does, as two conclusions | Uncertain what a dependency promises at the installed version and configuration |
| `firefly doubt` | 09 dissent | Run one independent investigation in a fresh context against a consequential untested assumption | A costly decision rests on an unverified assumption |
| `firefly context` | 10 context | Rebuild working context on demand and compress handoffs for a successor | On resumption or session handoff |
| `firefly ui` | 11 interface | Specify the UI states of a change before implementation and observe them on the real page | The change touches page states and interaction |
| `firefly arch` | 12 contract | Settle the interface a public promise rests on and write the contract back into the spec scenarios | A scenario changes a public interface, or two sides develop independently |
| `firefly tdd` | 13 tests | Carry the test discipline: a test worth writing first is watched failing on the unchanged baseline | Every dispatched test group during implementation |
| `firefly verify-web` | 14 browser | Verify browser-visible behavior in a fresh isolated session, one observation row per check | The change affects pages, interaction or visual output |
| `firefly debug` | 15 debugging | Obtain a signal that distinguishes faulty from normal behavior before diagnosing one failure | The failure cannot be reproduced reliably, or one repair left the symptom unchanged |
| `firefly review` | 16 verdict | Reviewers who did not produce the candidate judge the fixed package and return one of the four verdicts | Part of the full delivery path; separately commissionable |
| `firefly guard` | 18 security | Run a read-only check of a named scope's trust boundaries; mount gates into CI under write authority | A permission boundary changes, or a quality bar should become a pipeline check |
| `firefly perf` | 19 performance | Measure whether a change shortens the time a user actually waits, against a baseline under recorded conditions | A decision needs performance evidence |
| `firefly pr` | 20 delivery | Deliver an accepted candidate as a PR description written for the merge decider, and execute authorized actions | The candidate is accepted and a PR is needed |
| `firefly docs` | 23 records | Maintain the carriers a maintainer cannot recover from code: team vocabulary, decision records, main specs | Information worth keeping cannot be recovered from code |
| `firefly trace` | 24 signals | Agree runtime signal requirements with the spec and drill them on a candidate before release | A scenario promises users obtain a result, or the service has an on-call promise |
| `firefly archive` | 25 archive | Own three separately commissioned endpoints after `ACCEPT`: read-only readiness assessment, local archive, launch under its own mandate | After a delivery is accepted |
| `firefly retro` | 26 retro | Review an actual failure or repeated rework, locate the cause at one layer, propose revocable improvements | After a delivered change fails or needs rework |

## How it works

### Four entries

The user chooses the deliverable and the permitted effects; firefly chooses the entry and the next step. Four mandates about the same "month-end export restarts after refresh" problem end at four different endpoints:

- **"Find out why refresh starts the export over."** Enter an investigation: distinguish whether disconnecting ends computation or the page lost a still-running job ID. Return observations, cause or missing evidence; do not change the product even if the remedy is known.
- **"Propose recovery; do not implement it."** Enter spec and planning: clarify only unresolved intent, probe only consequential unknowns. Deliver scenarios that distinguish correct from incorrect behavior, task dependencies and checks; stop when the proposal is ready to start.
- **"Implement the recovery design that passed the ready decision."** Start at the first task with satisfied dependencies rather than repeating intake. The implementer supplies a candidate, verification checks affected behavior, independent review judges the integrated candidate. Deliver the verified change or an evidenced blocker; pushing, archiving and launching are not implied.
- **"Review this candidate."** Send the fixed candidate, spec and evidence directly to independent review. The terminal condition is one of the four verdicts, not a repair.

### Runtime subcommands

```bash
firefly init                  # check the global environment; run openspec init only when missing
firefly tasks all             # list unfinished tasks across active changes
firefly validate all          # explicitly validate the whole project
firefly list --json           # list changes
firefly status                # show artifact status for the only active change
firefly status --help         # explain the change ID and how to find or omit it
firefly spec --help           # list specification backend commands and options
firefly diagram <feature> <dir> # generate a timestamped .mmd and a rendered .svg
firefly doctor                # inspect managed assets on this platform (OK/MISS/DRIFT); modifies nothing
firefly repair                # restore missing or drifted managed assets, preserving backups
firefly snapshot worktree     # fix the candidate snapshot; --spec/--tasks for package versions
firefly record <subcommand>   # append one validated row to a handoff carrier
```

`firefly next` is the read-only skill entry: it extracts finished, promised-but-undone and unfolded goals from the session and the project, and proposes 3–5 items ordered by risk clearance, promise keeping, resumption, planned advance and debt cleanup — each with its evidence source, completion standard and matching firefly entry. When no signal exists, the gap is reported as is; no item is invented.

Run `firefly --help` for an overview and `firefly <command> --help` for parameters. A change ID identifies a change listed by `firefly list`. Use `firefly new <change-id>` to create a change scaffold. `firefly status` and `firefly show` select the only active change automatically or list candidates when several are active. Agents should pass the change ID when the mandate identifies it.

`firefly init` initializes a project. Both `validate` and `tasks` require a change ID or explicit `all`. For an existing change named `all`, run `firefly validate -- all` or `firefly tasks -- all`. Follow the `firefly docs` and `firefly archive` agent guides for spec sync and archive. Change commands discover the local project from subdirectories and accept an explicit `--root`. Use `firefly spec instructions`, `templates` or `schemas` for local queries. Explicitly select `firefly spec raw <command>` for native backend semantics. New projects default to Simplified Chinese prose and honor explicit project language requirements.

### Verdicts and escalation

An independent review returns exactly one of four verdicts:

- `ACCEPT`: the package is unchanged and every required role accepts, possibly with a reservation list.
- `REVISE`: the implementation or its tests are defective; the candidate must change, consuming the repair budget.
- `RECHECK`: an agreed check can be rerun on the current candidate; the candidate is unchanged and no repair round is consumed.
- `INSUFFICIENT_EVIDENCE`: the required evidence cannot be obtained under existing authority, tools or environment; escalate directly.

When new authority is needed, evidence is unavailable, retries make no progress or a promise has to change, `ESCALATE` returns three things: the current conclusion, the missing evidence or authority, and the owner who can supply it. Automatic execution stops there; no verdict or approval is made in the owner's place.

### Candidate states

A candidate travels from build to launch on one shared state table: **in progress → pending integration → pending verdict → accepted → releasing → live** (and **archived** once archive authority is granted). Passing verification moves it to pending integration; integration with a fixed review package moves it to pending verdict; acceptance to accepted; release authority advances it per the plan; the final stage verified against the original scenarios makes it live. A change to specs, standards or the candidate demotes affected observations and verdicts to history — an old verdict never clears a new candidate.

## Chinese OpenSpec Strict Validation

firefly provides Chinese-compatible OpenSpec strict validation through `firefly validate` for requirements whose body uses the Chinese normative terms `必须`, `不得`, `禁止`, or `应当`, without changing source specs. It checks those terms, injects `MUST` only in a temporary copy, and then runs native strict validation:

```bash
firefly validate all --root <project-root>
```

Run `firefly --help` for the runtime commands. The adapter validates main specs and active changes, supports only the `spec-driven` schema, and does not support Chinese section or heading keywords: keep `## Requirements`, `### Requirement:`, and `#### Scenario:` in English.

## Runtime dependencies

Run `firefly validate <change-id>` to validate one active change and its corresponding main specs. Successful validation prints the SHA-256 of the staged input before adapting modal verbs. Reinstall from a complete source package to rebuild a damaged installation baseline. The record command uses `flock` to serialize updates to carriers in the same directory.

Use `firefly review <change> --panel` for an independent panel and `firefly verify-formal` for a named invariant. Set model preferences in `.firefly/models.json` and project-specific checks in `.firefly/playbooks/`. Use `firefly config` to validate configuration and `firefly doctor --upstreams` to inspect upstream versions and adaptations. [Project configuration](firefly/references/project-configuration.md)

Installation, health checks and repair require Node.js 20 or later. OpenSpec 2.2.0 requires Node.js 22.20.0 or later. Git supports candidate snapshots and review. Install OpenSpec separately. `firefly init` runs `openspec init --tools none` in an isolated directory and imports the OpenSpec project config. Browser checks require an isolated browser automation tool. Mermaid rendering uses `mmdc` and task scanning can use `rg`. [Third-party notices](THIRD_PARTY_NOTICES.md)
