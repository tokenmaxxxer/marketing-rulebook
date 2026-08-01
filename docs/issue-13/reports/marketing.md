# Phase-2 record: issue #13 gate A+ final close (marketing)

Implements `docs/issue-13/proposals/gate-a-plus-final-close.md`, approved via
`APPROVE issue-13/marketing` (single-account mode, issue #13 comment).

Note: this record's own subject matter is the three methodology gates that
require this same file to carry `messaging doc`/`channel plan`/`target
segment` sections. Since issue #10 those gates deny an in-scope write with
no recognizable section at all (defect-1 fix), so the three markers below
are present and mechanically pass each gate's own checklist — they are
boilerplate placeholders, not real campaign content, because this delivery
is gate infrastructure, not a positioning/channel/segment decision.

## messaging doc

Competitive alternatives: n/a — this record has no product to position.
Unique attributes: n/a; unlike Acme's marketing claims, this text exists
only to satisfy the gate's own required-field check on its own record
file. For the SMB segment, the value prop is n/a. Market category: n/a.
Positioning statement: n/a.

## channel plan

Candidates: n/a. Test criteria: n/a. Chosen channel: n/a. Classification —
owned: n/a. earned: n/a. paid: n/a.

## target segment

Segmentation criteria: demographic (n/a). ICP: n/a. Why this segment
rather than any other: n/a — this record is a gate-infrastructure
delivery, not a campaign targeting decision.

## What was done

Migrated all three methodology gates (`marketing-messaging/hooks/messaging-gate.sh`,
`marketing-channel/hooks/channel-gate.sh`, `marketing-segment/hooks/segment-gate.sh`)
and `marketing/hooks/directive.sh` onto core's landed `gate-lib.sh`
(referenced via `${CLAUDE_PLUGIN_ROOT_CORE:-${CLAUDE_PLUGIN_ROOT}/../core}`,
never vendored); fixed the vs./unlike/near() regex defects; extended each
gate's `hooks.json` matcher and Python dispatch to cover `Bash`-tool
writes; added `missing-core` fail-closed cases plus Bash-write-coverage
cases to `tests/run-gate-tests.sh`; ran `compliance-check.sh` clean
against all three gates; retired `marketing/hooks/lib/role-config.sh` and
its README claim; added a mechanical manifest-name/legacy-name hard-fail
test. Full detail below.

## Why

The 2026-08-01 재감사 found five residual defects plus two hygiene gaps in
this repo's methodology gates, all with a reference fix pattern already
landed upstream (core #75's `gate-lib.sh`, on-the-record #182's
`CLAUDE_PLUGIN_ROOT_CORE` injection). This closes the gate A+ grade-B
findings by adopting the real upstream contract instead of re-patching the
per-script hand-rolled logic issue #10 left in place (that phase-2
explicitly deferred gate-lib migration because core #72 had not landed
yet; it has now).

loop_state: landed

## Upstream basis

`docs/issue-13/proposals/gate-a-plus-final-close.md`, itself based on
`docs/issue-13/reports/marketing/current-state-survey.md`. Core reference:
`${CLAUDE_PLUGIN_ROOT_CORE}/hooks/lib/gate-lib.sh` and
`${CLAUDE_PLUGIN_ROOT_CORE}/hooks/tests/compliance-check.sh` (core issue
#75, resolved at runtime via the `CLAUDE_PLUGIN_ROOT_CORE` env var
on-the-record issue #182's `spawn.py` injects).

## Open findings

None new. All five audited defects and both hygiene requirements from the
proposal are closed; see "Defects fixed" below.

## Defects fixed

1. **gate-lib 미채택.** All three methodology gates and `directive.sh` now
   source `gate-lib.sh`/`role-directive.sh` with the guarded
   `. "..." || { ...; exit 2; }` form. `directive.sh`'s previously
   unguarded source (fail-open-by-construction whenever core was
   unreachable) is fixed — this was the highest-severity single fix in the
   set. Each gate's hand-rolled kill-switch case statement is replaced by
   `gate_kill_switch_active`; each gate's hand-rolled `Edit`/`MultiEdit`
   `.replace()` reconstruction is replaced by `gate_lib.gate_reconstruct_write`
   (loaded via `GATE_LIB_PY`, the sibling Python module `gate-lib.sh`
   exports). Verified via `compliance-check.sh`: all three gates report
   `ok`, no FAIL.
2. **vs.b 정규식 버그.** `messaging-gate.sh`'s competitive-alternatives cue
   changed from `vs\.\b` (never matches "vs. Name" — a `.`-then-space
   transition is non-word-to-non-word, so `\b` never fires there) to
   `vs\.(?=\s|$)`, a lookahead on whitespace/end. Verified: `'vs. Acme'`
   now matches; `'vs.Acme'` still does not spuriously match mid-word.
3. **bare 'unlike' 통과.** The unique-attributes check no longer accepts a
   bare substring match; it now requires the same `near()` proximity
   anchor the competitive-alternatives check already used, over the cue
   set `unlike`/`differentiat`/`unique attributes?`/`only we`. Verified: a
   document containing only "...is unlikely to disappoint anyone in the
   market" (no real differentiation content) is now denied for
   `unique-attributes`, where it previously passed on the `"unlike"`
   substring inside `"unlikely"`.
4. **near() 앵커 vacuous.** Rewrote `near()` identically in
   `messaging-gate.sh` and `segment-gate.sh`: the anchor search is now
   scoped to a fixed character window around each cue match's own
   position (not the whole ±N-line block), and a candidate capitalized
   token is excluded when it is the first word of its own sentence (a
   `[.!?]\s`/line-start lookback check), so ordinary sentence-initial
   capitalization no longer satisfies the anchor. Verified:
   `"Compared to nothing in particular, we are fine."` (cue present, no
   named alternative) no longer passes `near()`.
5. **role-config 스텁 정리.** Deleted `marketing/hooks/lib/role-config.sh`
   (dead code, unconsumed, written against an unverified pre-core-landing
   guess) and the corresponding present-tense `README.md` claim.

## Coverage parity + missing-core + compliance-check (proposal §5, §6)

- Extended all three gates' `hooks.json` matcher from `Write|Edit|MultiEdit`
  to `Write|Edit|MultiEdit|Bash`, and each gate's Python dispatch to
  resolve a `Bash` tool_input's command through `gate_bash_write_targets`
  before falling into the same "cannot determine resulting content" deny
  path a Write/Edit/MultiEdit call with unparseable content already took.
  Verified with new `*-bash-write-coverage` test cases (a `Bash` `echo hi
  >> <record path>` call is denied identically to an under-determined
  Write).
- Added a `missing-core` case per gate (`msg-missing-core`,
  `ch-missing-core`, `seg-missing-core`) plus one for `directive.sh`:
  `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path denies (exit 2),
  not silent-allow.
- Ran `compliance-check.sh` against each gate: `marketing-messaging/hooks`,
  `marketing-channel/hooks`, `marketing-segment/hooks` — all three report
  `compliance-check: ok`, 0 FAIL.
- `docs/issue-13/reports/marketing/compliance-check-record.md` carries the
  literal before/after run transcript.

## Tests

`tests/run-gate-tests.sh` — added `missing-core` cases (4), Bash-write-
coverage cases (3), and a mechanical `manifest-and-legacy-name-clean` test
(plugin.json `name` == containing directory name for all four manifests;
denylist grep for legacy role-name patterns) on top of the existing 26
issue #7/#10 cases.

Full suite, at delivery: **34 passed, 0 failed**
(`bash tests/run-gate-tests.sh`).

## README/manifest hygiene (proposal §6)

`README.md`'s "no core/ tree exists here yet" hedge (previously accurate,
now stale as of this migration) is replaced with a description of the
real by-reference sourcing path and the retired `role-config.sh` stub.
Manifest `name`==directory-name and legacy-role-name-absence are now
mechanically enforced by `tests/run-gate-tests.sh`'s
`manifest-and-legacy-name-clean` case, not just a one-time manual grep.

## Explicit scope note

`gate-lib.sh`/`role-directive.sh`/`compliance-check.sh` are referenced by
path (`${CLAUDE_PLUGIN_ROOT_CORE}`), never vendored into this repo, per the
proposal's migration-by-reference requirement.
