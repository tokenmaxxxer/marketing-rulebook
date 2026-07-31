# Issue #2 — Current-State Survey (Phase 1)

Subject: issue-2

Status: Phase 1 (research/survey). No files removed, no gates changed. This
document only records what exists today so a Phase-2 executor (after human
APPROVE) has a concrete starting point.

## 1. What exists in this repo today

Contrary to the "may not exist yet" caveat in the task brief, all five
artifacts named in the issue **do already exist** in this rulebook (added by
the seed commit `83a4e44`, issue-170). Exact paths and summaries:

### 1.1 `marketing/agents/warrant-hunter.md`
A short markdown doc describing a "rotating-stance background hunt agent"
for the marketing role, explicitly marked as "adapted from
implementation-rulebook's `agents/warrant-hunter.md`" and as a "skeleton —
enumerate this role's own stance set before shipping." It documents the
role's decision boundary (`어떤 메시지로 어떤 채널에 도달할지`) and hand-off
target (`growth-analytics`). No hook wires this file to anything — there is
no cadence/scheduling config referencing it; it is documentation only.

### 1.2 Three gate scripts + their registrations
- `marketing/hooks/trailer-gate.sh` — PreToolUse gate on `Bash` matching
  `git commit`. Comment states explicitly: "Adapted from
  implementation-rulebook's trailer-gate.sh, role name substituted only
  (this file's logic is role-agnostic)." Enforces contract v3's
  `Subject: issue-<n>` commit trailer requirement.
- `marketing/hooks/record-fields-gate.sh` — PreToolUse gate on
  `Write|Edit|MultiEdit|NotebookEdit`. Role-specific: checks writes to
  `docs/issue-<n>/reports/marketing.md` for three required fields —
  `messaging-doc`, `channel-plan`, `target-segment` (sourced from this
  role's `produces` list, not copied from another role). Marked "Skeleton:
  field-presence checks are a placeholder."
- `marketing/hooks/handbook-trigger-gate.sh` — PreToolUse gate on `Bash`
  matching `git commit`. Currently an unconditional `exit 0` placeholder —
  comment says "harden per this role's actual write_scope ([]) before
  treating as load-bearing." No real verdict logic exists yet.
- Registration: `marketing/hooks/hooks.json` wires `SessionStart` →
  `directive.sh`, `PreToolUse` (Write/Edit/MultiEdit/NotebookEdit) →
  `record-fields-gate.sh`, and `PreToolUse` (Bash) → both
  `handbook-trigger-gate.sh` and `trailer-gate.sh`, in that order.

### 1.3 `marketing/hooks/directive.sh`
A `SessionStart` hook. Currently a **monolithic, role-owned script**, not a
stub: it has its own kill-switch (`MARKETING_CYCLE_OFF`), its own
`CLAUDE_ROLE` check, and prints the full role directive text inline
(decides/use_when/produces/write_scope/hand-off/boundary-case/record
pointer) via a heredoc. There is no `source` of any shared/core library and
no call to a `core_role_directive` function — the boilerplate (kill-switch
pattern, `CLAUDE_ROLE` gate, trap/fail-closed wrapper) is duplicated
verbatim across this file and the three gate scripts rather than shared.

### 1.4 Role-specific bits that must survive stubbing
- `write_scope: []` — this role currently declares no write surface of its
  own (per `plugin.json` description, `README.md`, and `directive.sh`'s
  printed directive). This is itself a role-specific fact that any stub or
  terminal-state config must not silently drop.
- No `loop_state` / terminal-state values are mentioned anywhere in this
  repo today. `record-fields-gate.sh` doesn't implement or reference a
  concept named `RECORD_FIELDS_TERMINAL_STATES`; it only checks required
  field presence in the record body. There is no existing role-specific
  "termination" divergence to preserve beyond the required-fields list
  itself (`messaging-doc`, `channel-plan`, `target-segment`) and the
  record path pattern (`docs/issue-<n>/reports/marketing.md`).
- `docs/specs/approvers.md` — populated as an empty allowlist stub (no
  logins yet); unrelated to the gate/directive migration but noted for
  completeness since it's part of this role's phase-gating machinery.

### 1.5 What does NOT exist
- No `core/hooks/lib/role-directive.sh` or any `core_role_directive`
  function reference anywhere in this repo.
- No reference to `core/hooks/tests/stub-check.sh` anywhere in this repo.
- No hunt-cadence/scheduler config for warrant-hunter beyond the markdown
  doc itself.
- No existing `RECORD_FIELDS_TERMINAL_STATES` variable or equivalent.

## 2. Discoverability of the "core" canon repo/reference

Checked for a sibling or related "core" repository in this environment:
- Listed the parent directory of the working directory
  (`/home/jwjung/.tokenmaxxxer/work/`): it contains only other rulebook
  worktrees (e.g. `accessibility-rulebook-issue-2-implementation`,
  `api-design-rulebook-issue-2-implementation`, `architecture-rulebook-...`,
  etc.) and their session logs — **no directory named `core` or
  `core-rulebook`, and no checkout of the core repo mentioned in the
  issue.**
- Searched broadly for anything named `core*` on the filesystem: only
  unrelated system paths (`/snap/core20`..`core26`, `/usr/bin/corelist`,
  `/usr/libexec/coreutils`, `/dev/core`) and two Claude-Code tool-cache
  directories under `/tmp/claude-1000/` (`core-check/`, `core-hooks/`)
  that appear to be leftover skill/plugin caches unrelated to the
  `tokenmaxxxer` core rulebook — they were not inspected further because
  they are outside this repo's scope and out of caution against pulling
  in ungoverned content from another session's cache.
- `git remote -v` shows only `origin` = the marketing-rulebook GitHub repo;
  no `core` remote is configured.
- No `gh` access was used to look up the core repo (not requested, and
  the issue's own text is the authoritative spec for phase-1 purposes).

**Conclusion: the actual `core/hooks/lib/role-directive.sh`,
`core/hooks/tests/stub-check.sh`, and `warrant/` plugin contents are not
discoverable in this environment.** The proposal in
`docs/issue-2/proposals/core-canon-migration.md` therefore proceeds on the
stated assumptions from the issue text alone (function name
`core_role_directive`, test path `core/hooks/tests/stub-check.sh`, plugin
name `warrant/`), flagged explicitly as assumptions to verify against the
real core repo before Phase-2 execution.

## 3. Scout note (per scout-directive)

Skip condition applied for tasks 1, 2, and 5: the issue text fully
prescribes the mechanic ("remove copy, reference core canon"; "remove gate
copies and hook registrations, core-side registration replaces them";
"confirm stub-check.sh passes and record it") — there is no open design
space to scout, so no search/investigation was run for those.

A lightweight check *was* warranted for tasks 3 (stub format) and 4
(`RECORD_FIELDS_TERMINAL_STATES` value) — those do involve a design
decision (how to shape the stub, what values to preserve). That check was
attempted per step 2 above (looking for the real `role-directive.sh` /
`stub-check.sh` to mirror their expected shape) but the source was not
discoverable in this environment. This is not a product/market decision,
so no full multi-stage web-search scout was run either way — this is an
internal migration whose correct shape is defined by the core repo's own
contract, not by external research. The proposal states its stub-shape
assumptions explicitly so they can be checked against the real core files
in Phase 2 before any code is written.
