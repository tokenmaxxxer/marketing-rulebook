# Implementation record: issue-2 core-canon migration (phase 2)

Subject: issue-2

Status: Phase 2 execution, following APPROVE of
`docs/issue-2/proposals/core-canon-migration.md`. This is the first
phase-2 write to this record file (contract v3 s19: unblocked now that
phase 2 is approved).

## why

Issue #2 requires this rulebook to migrate from role-owned copies of
shared machinery (gate scripts, hunt agent, directive boilerplate) to
references against core canon, so that shared logic lives once in core
instead of being duplicated and drifting per-role. This record documents
that migration having been carried out per the approved proposal.

## what was done

All five tasks from the proposal's "Summary of file-level actions" table
were executed as best-effort migration per the proposal's `[ASSUMPTION]`
flags (the real `core` repo is not present in this environment — see
"Verification gap" below).

1. **Task 1 — warrant-hunter removal.** Deleted
   `marketing/agents/warrant-hunter.md`. Updated `README.md`'s Layout
   section to point at core's `warrant/` plugin (core issue #63) instead
   of a local copy.

2. **Task 2 — gate copies removal.** Deleted:
   - `marketing/hooks/trailer-gate.sh`
   - `marketing/hooks/record-fields-gate.sh`
   - `marketing/hooks/handbook-trigger-gate.sh`

   Rewrote `marketing/hooks/hooks.json` to drop the `PreToolUse` block
   entirely, leaving only the `SessionStart` → `directive.sh` entry, per
   the proposal's Task 2 exact shape.

3. **Task 3 — `directive.sh` stub.** Replaced
   `marketing/hooks/directive.sh` with a thin stub that sources core's
   `core_role_directive` lib (`${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/
   role-directive.sh`, per the proposal's placeholder path) and passes
   the role name `"marketing"` plus the role-unique directive body as a
   heredoc. All role-unique content (decides/use_when/produces/
   write_scope/hand-off/boundary-case/record-path text) is preserved
   verbatim from the original file, including the Korean directive text,
   which was copied as-is and not translated.

4. **Task 4 — role config.** Added
   `marketing/hooks/lib/role-config.sh` (new `marketing/hooks/lib/`
   directory) carrying `RECORD_FIELDS_REQUIRED`,
   `RECORD_FIELDS_RECORD_PATH`, and an explicitly-empty
   `RECORD_FIELDS_TERMINAL_STATES=()` (no role-specific terminal
   `loop_state` exists for this role today, recorded as a fact rather
   than an omission), exactly as specified in the proposal's Task 4
   snippet. The file carries an inline `[ASSUMPTION]` comment noting it
   is currently unused pending core's actual gate-canon wiring, since the
   real consumption point (`core_role_directive`, a separate
   `core_record_fields_gate` function, or a config file core's canon
   reads directly) could not be confirmed against real core in this
   environment.

5. **Task 5 / stub-check verification — see "Verification gap" below.**

## Verification gap: `stub-check.sh` could not be run

`core/hooks/tests/stub-check.sh` could not be run — the core repo is not
present in this environment. Migration follows the proposal's
best-effort spec verbatim, including its `[ASSUMPTION]`-flagged
sections; this needs verification against real core before being treated
as final. In particular, unverified against real core:

- The exact calling convention of `core_role_directive` (arguments vs.
  stdin, kill-switch env var naming, `CLAUDE_ROLE` matching, fail-closed
  trap behavior).
- The `source` path used to locate core's `role-directive.sh` from a
  plugin-installed rulebook (relative path vs. an exported env var such
  as `CORE_HOOKS_LIB`).
- Whether core's `warrant/` plugin and core issue #66's gate registration
  actually resolve `CLAUDE_ROLE=marketing` correctly and cover this
  role's record path / required-fields data without a role-local script.
- Whether `RECORD_FIELDS_TERMINAL_STATES` (name and consumption point) is
  the field core's canon actually expects, or whether it is read by core
  at all yet.

No pass/fail result is claimed for `stub-check.sh` in this record — none
was produced. Phase-2 follow-up: obtain/checkout the real core repo and
re-run this task's verification once available, per the proposal's Task 5
plan.

## Record fields note

This role's directive (see `marketing/hooks/directive.sh`) nominally
requires messaging doc / channel plan / target segment as record fields
for marketing-content work. This record file is not a marketing-content
record — it is an infra/tooling migration record for issue-2's
core-canon migration — so those three fields do not apply here and are
not fabricated. This file instead documents the migration work itself
(file-level actions above) and the verification gap, which is the
substantive record content proper to this kind of phase-2 output.

## upstream basis

`docs/issue-2/proposals/core-canon-migration.md` (APPROVEd Phase-1
proposal) and `docs/issue-2/reports/implementation/survey.md` (Phase-1
survey of prior state) are the concrete upstream basis for every action
in this record; each task above was carried out exactly as that proposal
specifies, including its `[ASSUMPTION]` flags.

## loop_state

loop_state: blocked-on-external

The file-level migration is complete, but this record cannot be closed
out as final because `stub-check.sh` verification against the real core
repo (Task 5) has not been run and core is not available in this
environment.

### next steps

- Obtain/checkout the real core repo (or its hooks distribution) so that
  `core/hooks/tests/stub-check.sh` is runnable against this rulebook's
  new `directive.sh` and `hooks.json`.
- Run `stub-check.sh` against the migrated files and record the pass
  (command, exit code, core repo commit/ref) in this record.
- Re-verify each `[ASSUMPTION]`-flagged item listed under "Open findings"
  below against real core, and correct any file where the real contract
  differs from the proposal's best-effort shape.

### open-finding resolution path

Each open finding below resolves once the real core repo is available in
this (or a follow-up) environment: re-run `stub-check.sh`, diff the
assumed `core_role_directive` calling convention and `role-config.sh`
consumption point against the real core source, and update
`marketing/hooks/directive.sh` / `marketing/hooks/lib/role-config.sh` to
match if they diverge. This record should be revisited (loop_state moved
to a terminal state) once that verification pass lands.

## open findings

- Core repo (`core/hooks/lib/role-directive.sh`,
  `core/hooks/tests/stub-check.sh`, the `warrant/` plugin) is not present
  in this environment; `stub-check.sh` has not been run against the new
  `directive.sh`/`hooks.json`. This is the primary open item — see
  "Verification gap" above for the specific unverified assumptions.
- All `[ASSUMPTION]`-flagged items from the proposal (source path for
  `core_role_directive`, its calling convention, `role-config.sh`'s
  actual consumption point, and whether core's gate registration truly
  covers `CLAUDE_ROLE=marketing` without a role-local script) remain open
  pending access to real core.
