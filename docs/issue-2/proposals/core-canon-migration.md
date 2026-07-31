# Proposal: Migrate `marketing` role to core canon (issue #2)

Subject: issue-2

Status: Phase 1 proposal — NOT executed. Requires human APPROVE before any
task below is carried out (contract v3 s19). This document is the Phase-2
execution plan; execution itself is out of scope for this PR.

Basis: `docs/issue-2/reports/implementation/survey.md` found that all five
artifacts named in the issue already exist in this repo as role-owned
copies (not absent, so this is a genuine remove-and-replace migration, not
a from-scratch add). The actual core repo contents (`core/hooks/lib/
role-directive.sh`, `core/hooks/tests/stub-check.sh`, the `warrant/`
plugin) were not discoverable in this environment — every assumption below
that depends on core's exact shape is flagged `[ASSUMPTION]` and must be
verified against the real core repo before a Phase-2 executor writes code.

## Ordering constraint

Per the issue, this migration must land before this repo's "rulebook
maturation" issue reaches its own phase 2. Phase-2 execution of this issue
should therefore be scheduled/approved ahead of that other issue's phase 2.

## Task 1 — Remove warrant-hunter copy, reference core canon

Delete:
- `marketing/agents/warrant-hunter.md`

No hook or config in this repo references this file (survey 1.1), so
deletion has no other file's contents to update inside this repo.

Add, in its place, a short reference note so the role's doc set doesn't
silently lose the "we have a hunt agent" fact:
- Update `README.md`'s Layout section: replace the
  `marketing/agents/warrant-hunter.md` — rotating-stance hunt agent bullet
  with something like:
  > Warrant-hunt coverage for this role is provided by core's `warrant/`
  > plugin (core issue #63); this rulebook carries no local copy.
- `[ASSUMPTION]` core's `warrant/` plugin discovers/parametrizes
  per-role stance sets via `CLAUDE_ROLE` injection or a per-role config
  file it reads from this rulebook (e.g. a `roles/marketing.json`-style
  manifest, mirrored from `plugin.json`'s `decides`/`use_when`/hand-off
  fields). Verify against core's actual plugin before deleting the file,
  in case core still expects a per-role stance-set file to exist (in
  which case task 1's "remove" becomes "replace content, not delete
  path").

## Task 2 — Remove the 3 gate copies + their hook registrations

Delete:
- `marketing/hooks/trailer-gate.sh`
- `marketing/hooks/record-fields-gate.sh`
- `marketing/hooks/handbook-trigger-gate.sh`

Edit `marketing/hooks/hooks.json`: remove the `PreToolUse` entries that
point at these three scripts (the `Write|Edit|MultiEdit|NotebookEdit`
matcher block and the `Bash` matcher block currently listing
`handbook-trigger-gate.sh` + `trailer-gate.sh`), leaving only the
`SessionStart` → `directive.sh` entry local to this role:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh" }
        ]
      }
    ]
  }
}
```

`[ASSUMPTION]` core issue #66's own hook registration (in `core/hooks/`)
injects `CLAUDE_ROLE` and re-registers these three gates at the core
level, so removing the local registration does not leave the marketing
role ungated. Verify core's registration actually resolves
`CLAUDE_ROLE=marketing` correctly and that no marketing-specific matcher
(e.g. the record path `docs/issue-<n>/reports/marketing.md`, or the
required-fields list) needs to travel with the role rather than living in
core. If the required-fields list must stay role-local (likely, since it's
role-specific data, not gate logic), it should move into a small
role-config file, not the gate script itself — see Task 4.

## Task 3 — Replace `directive.sh` with a stub

Current `directive.sh` (survey 1.3) inlines: kill-switch check, role check,
and the full directive text. The stub keeps only what is genuinely
role-unique — the directive *content* — and delegates the shared
mechanics (kill-switch pattern, `CLAUDE_ROLE` gate, fail-closed trap,
heredoc emission) to core's `core_role_directive` function.

`[ASSUMPTION]` `core_role_directive`'s calling convention: takes the role
name and the directive body (or a path to it) as arguments/stdin and
handles the kill-switch env var naming, `CLAUDE_ROLE` matching, and
fail-closed trap itself. Exact signature must be confirmed against
`core/hooks/lib/role-directive.sh` before writing the real stub. Proposed
shape, to be corrected once that file is inspected:

```bash
#!/usr/bin/env bash
# SessionStart: marketing's role directive — thin stub over core canon.
# Shared mechanics (kill-switch, CLAUDE_ROLE gate, fail-closed trap,
# directive emission) live in core_role_directive; only this role's own
# directive content is defined here.
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/role-directive.sh"

core_role_directive "marketing" <<'DIRECTIVE'
YOU DECIDE: 어떤 메시지로 어떤 채널에 도달할지

USE_WHEN: 캠페인/포지셔닝이 걸릴 때

PRODUCES (required record fields): messaging doc, channel plan, target segment

WRITE_SCOPE: []

HAND-OFF: 퍼널 성과 해석은 → growth-analytics

BOUNDARY CASE: if the work in front of you drifts outside `decides` above,
stop and hand off per the arrow — do not silently absorb another role's
scope. Record the hand-off point in this role's record before opening the
next role's session.

RECORD: docs/issue-<n>/reports/marketing.md, phase-gated per contract v3 s19
(phase-1 homes only pre-Approve; this record is phase-2 output).
DIRECTIVE
```

Everything role-unique from the original file is preserved verbatim in the
heredoc: the `decides`/`use_when`/`produces`/`write_scope`/hand-off text,
the boundary-case instruction, and the record path pointer. Only the
kill-switch/role-gate/trap boilerplate (previously duplicated from
implementation-rulebook's pattern) is removed, since that's exactly the
"shared boilerplate" the issue says core now owns.

The exact `source` path (`${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/
role-directive.sh` above) is a placeholder — how a plugin-installed rule
book locates the core plugin's lib file (relative path vs. an env var core
exports, e.g. `CORE_HOOKS_LIB`) must be confirmed from core's actual
distribution mechanism before Phase-2 writes this line.

## Task 4 — Preserve role-specific differences via `RECORD_FIELDS_TERMINAL_STATES`

Survey 1.4 found no existing `loop_state`/terminal-state concept in this
repo — `record-fields-gate.sh`'s only role-specific data is its
required-fields list (`messaging-doc`, `channel-plan`, `target-segment`)
and the record-path suffix (`/reports/marketing.md`). There is nothing
resembling a terminal `loop_state` set for this role today.

Recommendation: since core's canon gate is expected to read a per-role
config rather than a per-role script (task 2), that config should carry:

```bash
# marketing role config, consumed by core's record-fields-gate canon
RECORD_FIELDS_REQUIRED=("messaging-doc" "channel-plan" "target-segment")
RECORD_FIELDS_RECORD_PATH="reports/marketing.md"
RECORD_FIELDS_TERMINAL_STATES=()   # no role-specific terminal loop_state today
```

`RECORD_FIELDS_TERMINAL_STATES` is left explicitly empty (not omitted) so
the absence of a role-specific difference is a recorded fact rather than a
silent gap — this is the "preserve real differences" instruction from the
issue applied honestly: marketing has none today, so the array says so.
`[ASSUMPTION]` the variable name and exact consumption point
(`core_role_directive`, a separate `core_record_fields_gate` function, or
a config file core's canon reads directly) must be confirmed against
core's real `role-directive.sh`/gate canon; the name
`RECORD_FIELDS_TERMINAL_STATES` is taken directly from the issue text.

If Phase-2 discovery of the real core code reveals this role *does* need
a non-empty terminal-state set (e.g. because core's default terminal
states don't cover a marketing-specific workflow end-state), that value
must be added here with a one-line justification, not left implicit.

## Task 5 — Confirm `core/hooks/tests/stub-check.sh` passes; record it

Not discoverable in this environment (survey §2), so this cannot be run
during Phase 1. Phase-2 plan:
1. Obtain/checkout the real core repo (or its hooks distribution) so
   `core/hooks/tests/stub-check.sh` is runnable against this rulebook's
   new `directive.sh` stub and hooks.json.
2. Run it against the migrated `marketing/hooks/directive.sh` and
   `marketing/hooks/hooks.json`.
3. Record the pass (with command + exit code, and the core repo
   commit/ref it was run against) in this role's phase-2 record,
   `docs/issue-2/reports/implementation.md` (the gated record file, not
   this survey/proposal tree), alongside the rest of the phase-2 work.

## Summary of file-level actions (Phase 2, post-APPROVE)

| Action | Path |
|---|---|
| Delete | `marketing/agents/warrant-hunter.md` |
| Delete | `marketing/hooks/trailer-gate.sh` |
| Delete | `marketing/hooks/record-fields-gate.sh` |
| Delete | `marketing/hooks/handbook-trigger-gate.sh` |
| Replace | `marketing/hooks/directive.sh` (stub over `core_role_directive`, role content preserved) |
| Edit | `marketing/hooks/hooks.json` (drop the 3 removed gates' PreToolUse entries; keep SessionStart) |
| Edit | `README.md` (Layout section: point at core canon instead of local copies) |
| Add (new, role-local config, exact filename TBD from core's contract) | role config carrying `RECORD_FIELDS_REQUIRED` / `RECORD_FIELDS_RECORD_PATH` / `RECORD_FIELDS_TERMINAL_STATES=()` |
| Record | `stub-check.sh` pass result → `docs/issue-2/reports/implementation.md` |

## Risks / open questions for the approver

1. Core's actual `role-directive.sh` contract is unverified in this
   environment — the stub shape above is a best-effort mirror of the
   issue's own description ("source shared function + call + role-unique
   part only"), not a copy of real core code.
2. If core's gate canon doesn't yet support a per-role config file (as
   opposed to a per-role script), Task 2/4 may need core-side changes
   first, which are out of this rulebook's control — flag back to core
   issue #66 if discovered during Phase 2.
3. `handbook-trigger-gate.sh` in this repo is currently an unimplemented
   placeholder (`exit 0` stub) — removing it loses no real logic, but
   confirm core's replacement actually implements the s21 handbook-sync
   check rather than also being a placeholder, or this role regresses
   silently from "unenforced" to "still unenforced but now invisible."
