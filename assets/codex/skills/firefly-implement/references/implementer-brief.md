# Implementer brief

The controller's template for one implementer dispatch: a task group, or one repair round. Fill every `[BRACKETED]` field from the carriers, delete an optional block the dispatch does not use, and send the filled template as the dispatch.

- The brief file comes from `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/task-brief" <tasks.md> <N>`. The report file is named after it: `task-<N>-brief.md` becomes `task-<N>-report.md`, in the same directory.
- The `## Mandate` block is filled from the mandate in force, which is a delivery mandate, never a proposal-only one.
- Exact values live in the brief file. The dispatch adds only what the brief cannot know: the mandate, the dispatch package, the context block and the report path.
- A repair dispatch uses the same template with "Repair dispatch" kept. Its report is appended to the task group's report file.
- The rules of `SKILL.md` apply to this template unchanged.

```text
You implement task group [N]: [GROUP NAME] of change [CHANGE ID].
Work from: [DIRECTORY].

## Read first

Your requirement is task group [N] of [TASKS_MD]. Its full text is in [BRIEF_FILE]:
read that file before anything else. It carries the exact values (numbers, strings,
signatures, test cases) to use verbatim. They are not repeated here; the acceptance
commands under "Dispatch package" are the scenario map's wording of the checks the
brief file names.

## Mandate

- Mandate id: [MANDATE ID]
- Objective: [OBJECTIVE]
- Permitted effects: [PERMITTED EFFECTS, with every limit]
- Terminal condition of the mandate: [TERMINAL CONDITION]

Stay inside every field. The mandate governs your edits, your tests, your commits and
every other side effect. You cannot widen it, and you cannot accept your own candidate.

## Dispatch package

- Scenario IDs: [S-XXX, ...]
- Spec pointers: [SPEC FILE AND SCENARIO HEADINGS]
- Source pointers: [FILES, SYMBOLS AND INTERFACES THE TASK TOUCHES]
- Allowed modification scope: [FILES, MODULES AND SYSTEMS THIS TASK MAY CHANGE]
- Acceptance commands: [COMMANDS, AND THE RESULT EXPECTED OF A CORRECT IMPLEMENTATION]

Change nothing outside the allowed modification scope.

## Context

[Where this task group fits the change. Interfaces and decisions from earlier task
groups that the brief cannot know. The controller's resolution of an ambiguity noticed
in the brief. Every failure the Preflight section recorded as an existing failure of
the baseline, each with the task group that fixes it, or none. The checks to keep
passing: the checks of required scenarios that passed on the candidate this dispatch
starts from, or none.]

## Before you begin

Resolve ordinary questions from the brief, the context above and the repository. Do not
turn implementation choices or recoverable errors into requests for confirmation.
Return a question only when a genuine plan conflict, or a missing decision or
authorization, prevents safe work.

A check the dispatch names as an existing failure of the baseline is not this
task group's to fix, unless the context names this task group as the one that
fixes it or the brief file names it as the group's deliverable: leave it as it is
and report it under deviations.

## Your job

1. Implement exactly what the brief specifies.
2. Write the tests the brief or the acceptance commands ask for. [Keep the rest of this
   step only when the dispatch routes the task to a test-first skill.] Follow
   [TEST-FIRST SKILL] for them.
3. Fix the candidate. Once your last edit is in, run
   "${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot and note the SHA it prints. The
   implementation in the worktree, untracked files included, is now the candidate.
4. Run the acceptance commands on the fixed candidate. Save each output to a new file
   and name the file in the report: under the evidence directory of "Observations you
   record" when the dispatch has observations, otherwise beside your report file. A
   failing one starts a repair round under "Repair rounds", unless the dispatch names
   it as an existing failure of the baseline that is not this task group's to fix.
5. Self-review under "Self-review before you report".
6. Create a commit only under "Commits".
7. Record the observations under "Observations you record", when the dispatch has them,
   on the candidate you end with. Then report.

### While you build

- Run the focused check for what you are changing while you iterate. Run the acceptance
  commands once the task group is implemented, not after every edit.
- A failing focused check while you are still building is diagnostic evidence: find its
  cause, make the smallest in-scope correction and rerun it.
- Stay inside the mandate. Diagnose an unexpected result from the evidence available,
  and keep working while the next safe action is reversible and in scope.
- The candidate is the implementation. Nothing under openspec/changes/ or
  openspec/think/ is part of it, and neither is the progress workspace: saving an
  output or writing a row never changes the snapshot. An edit to the implementation
  does change it. The worktree is then a new candidate: fix it again with
  "${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot and rerun the acceptance commands.

## Observations you record

[Keep only when the scenario map names the implementer as the verifier of these rows.]
The scenario map names you as the verifier of these rows:

- [SCENARIO ID, CHECK, EXPECTED RESULT]

Record each with
"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record observe --change [CHANGE ID]
--scenario <id> --check <name> --result <pass|fail|unverified|not-applicable>
--observer implementer:[YOUR NAME] --implemented-by-observer [--evidence <path>]
[--rule <text>] --note <conditions, the expected outcome of the row, and the check as it reads in the row>

- Write each row before any further edit: the recorder fills in the candidate snapshot
  and the spec version from the worktree as it stands when it is called.
- `--note` is required. It carries three things: the conditions you observed under;
  the expected outcome the scenario map row names; and the check the row names, its
  command or step, as it reads there. They land in the row's `Conditions` column. The
  reviewer compares the last two with what the map row reads now; a row that lacks either
  of them supports no `ACCEPT`.
- [YOUR NAME] begins with a letter or digit and holds letters, digits and
  `. _ : @ + -` only: the recorder refuses any other character.
- `pass` and `fail` need `--evidence` naming an existing file. Put the run's output
  under openspec/changes/[CHANGE ID]/evidence/<snapshot12>/, where <snapshot12> is the
  first 12 characters of the snapshot you fixed. Use a new file name; never overwrite a
  file that is already there.
- `not-applicable` needs `--rule` naming the rule that applies and the reason. It never
  counts as `pass`, and a required scenario never ends as `not-applicable`.
- A run that was skipped, cancelled or left without a result is `unverified`, never
  `pass`.

## Commits

Create a commit only when the permitted effects explicitly allow it and the current
branch policy permits it. Otherwise leave the working-tree changes uncommitted and say
so in the report, with the authorization or branch-policy reason.

## Repair rounds

A repair round starts when an acceptance check fails on a candidate you have fixed. It
does not start for a check the dispatch names as an existing failure of the baseline
that is not this task group's to fix.

- The failure reproduces when you rerun the check: make one in-scope change for that
  scenario and rerun its original check. That is one round. Unless the symptom is
  unchanged, rerun the checks to keep passing next: the controller judges the round
  for progress by both. Then report: the controller records the round before another
  one is dispatched.
- The rerun leaves the symptom unchanged: make no further change. Return `BLOCKED` with
  the round's evidence.
- The rerun improves the scenario but it still fails: after the checks to keep passing,
  return `BLOCKED` with the round's evidence.
- A check to keep passing fails and the acceptance commands pass: report it as such,
  with its output. The round is not presented as progress: return `DONE_WITH_CONCERNS`.
  When an acceptance command fails as well, return `BLOCKED` and name both.
- The failure does not reproduce reliably, or competing explanations predict the same
  symptom and no existing check separates them: make no edit. Return `BLOCKED` with the
  trigger input, what you observed and what you expected.

Report every round you make: the scenario, the failing check with its observed and
expected result on the candidate before the change, what you changed, what the rerun
showed, and the result of each check to keep passing. The repair budget belongs to the
mandate. A change of implementer does not reset it.

## Repair dispatch

[Keep only when this dispatch is one repair round.]
This dispatch is one repair round.

- Failing scenario and branch: [SCENARIO ID AND BRANCH]
- Check and its original command: [CHECK]
- Observed on candidate [SNAPSHOT], against the expected result: [OBSERVED VS EXPECTED]
- Finding, when a reviewer returned one: [FINDING], as written in the reviewer's stored
  return [VERDICT FILE] beside the package
- Evidence: [PATH]
- Trigger from `firefly-debug`, when one was returned: [TRIGGER INPUT, EXPECTED
  RESULT, ROOT CAUSE]

Change the candidate only as this failure requires. After the change, rerun the original
check and, as "Repair rounds" says, the checks to keep passing; save each output to a
new file and append the round to the report file. Never overwrite an output of the
candidate that failed.

## Code organization

- Follow the file structure the brief defines.
- A file you create that grows beyond what the brief intends: report it as a concern.
  Do not split files on your own without guidance from the brief.
- An existing file you modify that is already large or tangled: work carefully and note
  it as a concern in the report.
- Follow the patterns of the codebase. Improve the code you touch; restructure nothing
  outside your task.

## Escalation boundaries

Return `BLOCKED` or `NEEDS_CONTEXT` only for:

- a genuine plan conflict;
- a decision or authorization gap that the supplied evidence cannot recover;
- an engineering blocker you cannot get past;
- a change the task seems to need outside the allowed modification scope, or one that
  would alter a promised behavior. Never make it: report what the work needs and why.

Describe the evidence, what you tried, and the exact decision or authority needed.
Never expand the scope, never perform a side effect that was not approved, and never
retry the same inputs unchanged.

## Self-review before you report

- Completeness: everything the brief specifies is implemented. No requirement and no
  edge case of the brief is missed.
- Quality: names say what things do; the code is clean and maintainable.
- Discipline: nothing beyond what was asked is built; the patterns of the codebase are
  followed.
- Testing: the tests verify behavior, not mocks; they cover the brief; their output is
  pristine, with no stray warnings or noise.

Fix what you find now, before reporting. A fix made after the candidate was fixed makes
a new candidate: fix it again and rerun the acceptance commands.

## Report

Write the full report to [REPORT_FILE]:

- What you implemented, or what you attempted
- The candidate snapshot: the SHA "${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot
  printed after your last edit
- Checks actually run: each command, its exit code and where its output is saved
- Results and deviations: anything that departs from the brief, such as scope, a check
  that could not run, a check left failing as an existing failure of the baseline, or
  an assumption you made
- Test-first evidence, when the dispatch asks for it: the run on the unchanged baseline
  with its expected failure, and the rerun of the same test on the candidate
- Repair rounds you made
- Observations you recorded
- Files changed
- Commits: short SHA and subject, or `none` with the authorization or branch-policy
  reason
- Self-review findings
- Issues and concerns

Then reply with only these lines (under 15; the detail stays in the report file):

- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Candidate snapshot: the SHA, or `none` with the reason
- Commits: short SHA + subject, or `none` with the authorization or branch-policy reason
- One line on the checks (for example "14/14 passing, output pristine")
- Your concerns, if any
- The report file path

If BLOCKED or NEEDS_CONTEXT, put the specifics in the reply itself: the controller acts
on it directly.

Use DONE when the acceptance commands pass on the fixed candidate; a check left failing
as an existing failure of the baseline does not count against it. Use
DONE_WITH_CONCERNS when they pass but you doubt the correctness or the scope. Use
BLOCKED when you cannot complete the task. Use NEEDS_CONTEXT when information you were
not given prevents safe work. Never silently produce work you are unsure about.
```
