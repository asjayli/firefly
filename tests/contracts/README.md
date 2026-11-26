# Contract anchors

One file per skill: `tests/contracts/<skill-id>.txt`. `tests/test-skill-contracts.sh` applies each file to the skill's `SKILL.md` concatenated with every `references/*.md` beside it, on both rendered platform copies. A miss fails the lint.

## Format

One entry per line. Leading and trailing whitespace is ignored.

| Line | Meaning |
|---|---|
| `@design NN` | The design position this skill implements. `NN` is two digits; a skill that hosts absorbed positions writes `NN,MM` (for example `@design 16,17`). It must equal `metadata.design` in the skill's frontmatter. |
| `+<tag>: <phrase>` | The skill text must contain `<phrase>`. Fixed string match, case-sensitive. |
| `-: <phrase>` | The skill text must not contain `<phrase>`. |
| `# ...` | Comment. |

`<tag>` is one of:

| Tag | Pins |
|---|---|
| `trigger` | When the skill is entered. |
| `mandate` | What the skill may and may not do. |
| `input` | What it must be given. |
| `output` | What it writes, and to which carrier. |
| `verdict-or-state` | How a verdict value, status or candidate state is used. |
| `handoff` | Where work goes next. |
| `stop` | Where it stops and escalates. |

A `+` line without a known tag is a format error.

## Rules

- The phrase must match inside one file. A phrase is never split across files.
- One file is applied to both platform copies, so a phrase must be identical after rendering on each platform. Do not include the rendered value of a platform token (a platform home path, a dispatch tool name); anchor on the wording around it instead.
- Keep at least one `+` entry under each of the seven tags, at least 10 `+` entries in all, and at least three `-` entries: `APPROVE`, a retired skill name, and the skill's most typical overreach (for example a review that repairs the candidate it is judging).
- A `+` entry pins a place where the skill could go wrong: a trigger, an authorization boundary, an output carrier, the use of a verdict value or status, a stop condition. Do not pin a sentence any skill would satisfy.
- Provenance notes live in an HTML comment (`<!-- ... -->`) right after the frontmatter. The retired-skill-name rule of the structure lint skips HTML comments, so the note may name the skill a file evolved from. A `-` entry does not skip them: it is matched against the whole rendered text. Pick for the retired-name `-` entry a name that appears in no comment of the skill.
- When a pinned sentence is rewritten, move its entry to the equally critical phrase of the new sentence; a stale `+` fails the lint, a dropped `+` silently stops guarding.

## Environment

The lint reads these variables, which exist so the test can lint a temporary tree or check a skill before it is rendered:

| Variable | Default | Effect when set |
|---|---|---|
| `FIREFLY_SKILLS_ROOT` | `assets/shared/skills` | |
| `FIREFLY_RENDERED_ROOT` | `assets` (expects `<root>/<platform>/skills` beneath it) | |
| `FIREFLY_CONTRACTS_ROOT` | `tests/contracts` | |
| `FIREFLY_SKIP_ANCHORS` | unset | `1`: skip the anchor file and the rendered copies; lint the source alone. |
| `FIREFLY_LINT_ONLY` | unset | `1`: run the lint only, without the negative self-check. |
