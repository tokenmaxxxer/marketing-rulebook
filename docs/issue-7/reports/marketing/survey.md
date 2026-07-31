# Survey: marketing's current directive/gate state vs. the hook-machine bar (issue #7)

Subject: issue-7

Status: Phase-1 research artifact — no plugin files touched by this
document.

## What marketing has today

`marketing/hooks/hooks.json` wires exactly one hook: `SessionStart` ->
`marketing/hooks/directive.sh`. There is no `PreToolUse` hook, no
methodology gate, no state file, and no `tests/` directory for this role.

`marketing/hooks/directive.sh` sources core's
`role-directive.sh` and emits a directive via `core_role_directive`. Its
`PRODUCES` line (added in issue #6, phase-2 of issue #1) is one line per
field with a methodology *pointer* only:

```
PRODUCES (required record fields):
  messaging doc (positioning canvas — see docs/issue-1/proposals/rulebook-maturation.md §b),
  channel plan (Bullseye 3-phase test — see same),
  target segment (STP + ICP — see same)
```

It names the methodology but states none of its stages, judgment
criteria, or prohibitions — a session reads a title, not instructions.
There is no PHASE 1 directive text at all (no proposal-norms text
inlined; issue #1's proposal §a lives only in that proposal document, not
in `directive.sh`).

`marketing/hooks/lib/role-config.sh` carries only
`RECORD_FIELDS_REQUIRED` (three field-name strings),
`RECORD_FIELDS_RECORD_PATH`, and an empty
`RECORD_FIELDS_TERMINAL_STATES`. It is marked `[ASSUMPTION]` — "currently
unused pending core's actual gate-canon wiring" — i.e. even the field
*names* are not confirmed to be consumed by any live gate today, let
alone checked for methodology structure. `docs/issue-1/reports/marketing.md`
(the issue-6 phase-2 record) confirms this explicitly: it deferred the
`RECORD_FIELDS_METHODOLOGY` extension pending issue-2's still-open
`stub-check.sh` verification gap, and that record's own `loop_state` is
`blocked-on-external`.

Net: the three methodologies adopted in issue #1/#5/#6 (Dunford
positioning canvas, Bullseye 3-phase, STP+ICP) exist as (a) a proposal
document and (b) a one-line pointer in `directive.sh`. Nothing machine-
verifies that a `messaging.md`/`channel-plan.md`/`target-segment.md` (or
whatever the record actually names) contains the mandatory components
issue #1 §b enumerated. A session can satisfy the field name
("messaging doc: done") while omitting every mandatory component (no
competitive-alternatives section, no per-segment value prop) and nothing
in this plugin would catch it.

## The hook-machine bar (implementation/coding role, and pricing role)

Read from `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/*`
and `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/*`
(sibling rulebooks on this machine, not part of this repo — read for
rigor reference only, per the "reference, don't copy" canon-scripts
constraint):

- **`directive.sh`** carries multi-paragraph `YOU_DECIDE`/`USE_WHEN`/
  `PRODUCES`/`HAND_OFF` blocks with named rules (e.g. coding's
  "SCOPE-EXCEEDED RULE", "HONEST CLAIMS (no-mock)"), not one-line
  summaries.
- **A `PreToolUse` gate** (`coding-progress-gate.sh`, pricing's
  `methodology-gate.sh`) that: installs a fail-closed `trap __fc EXIT` as
  its *first* statement (any abnormal exit maps to deny, since
  PreToolUse treats non-2 exit codes as fail-open); reads the tool-call
  JSON payload from stdin; resolves the target file path against the
  real project root (`CLAUDE_PROJECT_DIR` or `git rev-parse
  --show-toplevel`, with a plausibility check); restricts itself to a
  narrow regex-matched write surface (e.g.
  `^docs/issue-[0-9]+/proposals/.*pricing.*\.md$`); reconstructs the
  resulting file content for `Write`/`Edit`/`MultiEdit` (denying if it
  cannot, rather than guessing); and runs a Python judge, itself wrapped
  in `try/except` with a fail-closed `except Exception` branch, that
  checks for named required elements via keyword/regex matching and
  denies (`exit 2`) naming exactly which elements are missing.
- **State/ordering tracking** where the methodology has a sequencing
  constraint: coding's gate reads a *different* role's record
  (`verify.md`) for `severity: blocking` findings `addressed_to: coding`
  and denies a `git commit` until the coding record shows a
  `resolved_findings` entry and the verify record's `loop_state:
  cleared`. This is the "state tracking to force ordering" pattern the
  issue asks about, and it is done via plain-text field parsing in the
  git-tracked record files, not a separate state database.
- **A `state.sh` SessionStart hook** (informational only, never blocks)
  that greets the resuming session with branch/PR/record status.
- **Gate tests** at repo-root `tests/run-gate-tests.sh`: spawns the real
  gate script as a subprocess in a throwaway git repo, feeding it a JSON
  tool-call payload on stdin, and asserts exit code 0 (allow) or 2
  (deny) for each case (record-complete/record-empty/foreign-path,
  commit-with/without-trailer, blocking-finding resolved/unresolved).

## Gap line (what marketing already meets vs. is missing)

| Bar element | marketing today |
|---|---|
| Directive names a methodology per field | Met (issue #6) |
| Directive states stages/judgment-criteria/prohibitions per facet | **Missing** — one-line pointer only |
| PreToolUse methodology gate on the record write surface | **Missing** — no PreToolUse hook exists at all |
| Fail-closed trap-at-top pattern | **Missing** — no gate script exists to have one |
| Ordering/sequencing state tracking | **Missing**, and arguably not needed — issue #1's three methodologies (positioning canvas, Bullseye, STP+ICP) do not have an inter-field ordering dependency the way coding's build->verify->resolve cycle does; this is a design question for the proposal, not a settled gap |
| `state.sh` informational SessionStart hook | **Missing** |
| Gate tests at repo-root `tests/` | **Missing** — no `tests/` directory exists in this repo |
| `role-config.sh` methodology structure | **Missing**, and explicitly deferred in issue #6's record pending issue-2's `stub-check.sh` verification gap (still open as of this survey — no `core/` directory present in this environment) |

## Sources read

- `marketing/hooks/directive.sh`, `marketing/hooks/hooks.json`,
  `marketing/hooks/lib/role-config.sh` (this repo)
- `docs/issue-1/proposals/rulebook-maturation.md`,
  `docs/issue-1/reports/marketing.md` (this repo)
- `gh issue view 1`, `gh issue view 5`, `gh issue view 6`, `gh issue view 7`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/directive.sh`,
  `coding-progress-gate.sh`, `state.sh`, `hunt-guard.sh`, `hooks.json`
- `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`
- `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/directive.sh`,
  `methodology-gate.sh`
