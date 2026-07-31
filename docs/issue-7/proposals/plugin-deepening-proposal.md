# Proposal: plugin deepening — enforcement mechanism for marketing's adopted methodology (issue #7)

Subject: issue-7

Status: Phase 1 proposal — NOT executed. Requires human APPROVE before
any task below is carried out (contract v3 s19). This document is a
design/spec for phase-2 implementation; no `marketing/hooks/*` file, no
`tests/` file, and no `role-config.sh` edit is made by this PR.

Basis: `docs/issue-7/reports/marketing/survey.md` (current-state gap
survey), `docs/issue-7/reports/marketing/scout-brief.md` (hook-machine
rigor scouted from sibling rulebooks), and the previously APPROVEd
`docs/issue-1/proposals/rulebook-maturation.md` §b/§c (the methodology
norms this proposal enforces — referenced, not restated in full; see
that document for the source citations and rationale behind each
methodology choice). Structural/rigor precedent (referenced by path
only, content not copied per canon-scripts "reference, don't copy"):
`/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
and
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`.

## 1. Directive deepening design

`marketing/hooks/directive.sh`'s `PRODUCES` line today is a title per
field. This proposal specifies replacing it (phase-2 drafting decision;
exact heredoc wording is not fixed here) with per-facet blocks matching
the `YOU_DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND_OFF` structure already used
by `coding/hooks/directive.sh`, each carrying stages, judgment criteria,
and prohibitions — no one-line summaries.

### PHASE 1 facet (proposal-writing norms — issue #1 §a, restated as
executable instruction, not prose pointer)

- **Stages**: (1) problem/goal statement, (2) current-state survey
  reference, (3) named methodology citation, (4) required-sections
  checklist for the phase-2 deliverable, (5) evidence-citation for every
  substantive claim, (6) `[ASSUMPTION]` flagging, (7) status header line
  per contract v3 s19.
- **Judgment criteria**: a claim is "evidence-cited" only if it points to
  either a named external framework/source or an internal artifact this
  repo already has (survey finding, existing file content) — an
  unattributed "best practice" phrase fails this criterion.
- **Prohibitions**: no phase-1 proposal may skip the survey-reference
  step (issue #1 §a.2 makes this a hard requirement, not optional
  context); no phase-1 document may claim `[ASSUMPTION]`-worthy content
  as confirmed fact.

### PHASE 2 facet, per record field (issue #1 §b, restated as executable
instruction per field)

For each of the three required record fields
(`messaging-doc`/`channel-plan`/`target-segment`), the directive states,
per field: the named methodology, the ordered stages of that methodology
(e.g. Bullseye: brainstorm candidates -> cheap-test each -> select with
rationale), the judgment criterion for "done" (e.g. messaging doc: a
one-line positioning statement exists AND is traceable to a named
competitive alternative, not merely present), and the field-specific
prohibition (e.g. channel plan: selecting a channel without a stated
test rationale is a prohibited shortcut — Bullseye's whole point is
test-before-commit, not pre-existing preference).

This is directive **text only** — a judgment call a human/session reads
and follows, not machine-enforced by the directive script itself (the
`SessionStart` hook cannot block anything; it only emits text). Section
2 below is the machine-verification layer.

## 2. Methodology gate design

New file (phase-2, NOT created by this PR):
`marketing/hooks/methodology-gate.sh`, wired as a `PreToolUse` hook
matching `Write|Edit|MultiEdit` in `marketing/hooks/hooks.json`,
structurally mirroring
`/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
(rigor reference only — the checked elements below are marketing-
specific, not copied text):

- Fail-closed `trap __fc EXIT` installed as the first statement.
- Kill switch: `export MARKETING_METHODOLOGY_GATE_OFF=1`.
- Write-surface regex: `^docs/issue-[0-9]+/proposals/.*marketing.*\.md$`
  (phase-1 proposals) and `^docs/issue-[0-9]+/reports/marketing\.md$`
  (phase-2 record) — silent (`exit 0`) on any other path, per pricing's
  pattern of "not this gate's business."
- Content reconstruction for `Write`/`Edit`/`MultiEdit`; deny if the
  resulting text cannot be determined from the tool-call payload.
- Per-field required-element keyword/regex checks, run only when the
  corresponding field section is present in the write (a record grows
  field-by-field across a phase-2 session; the gate should not demand
  all three fields be complete on every single write — see "state
  tracking" below for how partial writes are handled):

  | Field | Required elements checked (fail-closed if any absent when the field section exists) |
  |---|---|
  | messaging doc | competitive-alternatives language present; unique-attributes language present; per-segment value-prop language (not one generic value-prop sentence — checked by requiring the word "segment" to co-occur with "value prop"/"benefit"); market-category language; a one-line positioning-statement marker |
  | channel plan | candidate-channel list (checked via a plural-channel-name heuristic or an explicit "candidates:" marker); test-criteria/rationale language ("test", "criteria", or "rationale" present per candidate context); chosen-channel-with-rationale marker; owned/earned/paid classification keywords |
  | target segment | segmentation-criteria naming (at least one of demographic/firmographic/behavioral/psychographic); ICP-definition marker (not a bare demographic label — checked by requiring more than one criterion type or an explicit "ICP:" block); targeting-rationale language ("why this segment", "over", "rather than") |

- Denial message names exactly which element(s) are missing and cites
  `docs/issue-1/proposals/rulebook-maturation.md` §b as the norm source,
  mirroring pricing's citation-in-denial pattern.

### State tracking

Issue #7 asks for state tracking "if methodology-level ordering
constraints exist." Per the scout-brief's "one pattern to skip": this
proposal finds **no cross-role or cross-field ordering dependency**
among the three adopted methodologies comparable to coding's
build->verify->resolve cycle — messaging doc, channel plan, and target
segment are produced independently and the issue #1 proposal never
states an order among them. The only ordering that IS intrinsic to a
single methodology is Bullseye's own "brainstorm broadly before
selecting" shape (issue #1 §b: "Candidate channel list (brainstormed
broadly, not pre-filtered to one)" then "Chosen channel(s) ... (post-
test selection, not pre-test preference)").

Design for that one intra-field ordering constraint: rather than a
separate state file, the gate checks **within a single field's current
text** that a candidate-list marker exists whenever a chosen-channel
marker exists (i.e. a document cannot show a "chosen channel" section
without also showing a "candidates considered" section in the same
text) — this is a same-document structural check, not a persisted state
machine, because both stages of Bullseye live in one field's content by
design (issue #1 §b lists both as mandatory components of the same
`channel plan` field). No `state.sh`-style file or `loop_state`
cross-record tracking is proposed for marketing at this time, since no
adopted methodology here spans multiple record files the way coding's
verify-then-resolve does. If a future methodology round introduces a
genuine cross-role or cross-record ordering constraint, that would
warrant the coding-style pattern (a `loop_state` field in
`docs/issue-<n>/reports/marketing.md`, checked by a separate gate against
the counterpart role's record) — not before.

### `role-config.sh`

Per issue #6's still-open deferral (`docs/issue-1/reports/marketing.md`:
`loop_state: blocked-on-external`, blocked on issue-2's `stub-check.sh`
verification gap against real core), this proposal does **not** commit
to extending `RECORD_FIELDS_REQUIRED`/`RECORD_FIELDS_METHODOLOGY` in
`role-config.sh` as part of phase-2 execution. `[ASSUMPTION]` the
methodology-gate design above works independently of `role-config.sh`
(it hardcodes its own regex/keyword checks, as pricing's gate does,
rather than reading role-config), so this gate can be implemented
without first resolving that deferred structural edit. Whether
`role-config.sh` should still be extended once the verification gap
closes remains an open question for the approver (carried over from
issue #1's own open question 2), not resolved here.

## 3. Gate test design

New file (phase-2, NOT created by this PR): repo-root
`tests/run-gate-tests.sh`, mirroring
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`'s
subprocess-invocation shape (spawn the real gate script against a
throwaway git repo, feed a JSON tool-call payload on stdin, assert exit
0/2).

Proposed cases:
- `allow`: a `Write` to `docs/issue-<n>/proposals/marketing-x.md`
  containing all five messaging-doc elements -> exit 0.
- `deny`: same target, missing competitive-alternatives language -> exit
  2, message names `competitive-alternatives` as missing.
- `allow`: `docs/issue-<n>/reports/marketing.md` write with a complete
  channel-plan section (candidates + test-criteria + chosen + rationale
  + owned/earned/paid) -> exit 0.
- `deny`: channel-plan section with a "chosen channel" marker but no
  candidate-list marker -> exit 2 (intra-field ordering check).
- `allow`: a write to an unrelated path (e.g.
  `docs/issue-<n>/reports/qa.md`) -> exit 0 (gate is silent, per
  write-surface scoping).
- `deny`: malformed/unparseable JSON payload -> exit 2 (fail-closed).
- `allow`: `MARKETING_METHODOLOGY_GATE_OFF=1` set -> exit 0 regardless of
  content (kill-switch verification).

## 4. Supporting agents/checklists

No dedicated sub-agent is proposed. The three methodologies (Dunford
canvas, Bullseye, STP+ICP) are single-session, single-role deliverables
per issue #1's own rationale (§c: "rigor proportionate to a
produces-only, `write_scope: []` role") — they do not involve a
repeated multi-step procedure spanning tool invocations the way, e.g., a
warrant-hunter's repeated probing does. Instead, this proposal specifies
a lightweight **inline checklist artifact**: a `MARKETING_CHECKLIST.md`
reference block (phase-2, NOT created by this PR) enumerating the same
three per-field mandatory-component lists as the gate checks
mechanically, to be surfaced by the `directive.sh` deepening in section
1 above so the session sees the checklist before the gate would ever
deny it — the gate is the enforcement backstop, not the primary UX.

## 5. Sequencing and constraints

- Canon scripts (core's `role-directive.sh`, any shared gate library)
  are referenced only, never copied, per core `canon-scripts.md`
  (referenced by path convention; not present as a checked-out file in
  this environment — `[ASSUMPTION]` this constraint's exact file
  location, consistent with how `docs/issue-1/proposals/
  rulebook-maturation.md` already treats core-canon references it
  cannot locally verify).
- `write_scope: []` and role boundaries are unchanged by this proposal;
  the new gate only adds mechanical enforcement over marketing's own
  existing write surface (its own proposals and its own record), it
  does not expand what marketing may write.
- This proposal's phase-2 execution requires: (1) human APPROVE of this
  document (contract v3 s19), and (2) no additional cross-repo
  dependency — unlike issue #1's phase-2, this gate design does not
  require `role-config.sh` changes or issue-2's verification-gap
  closure, since section 2 above hardcodes its checks rather than
  reading role-config.

## Open questions for the approver

1. Whether the keyword/regex heuristics sketched in section 2's table
   are the right granularity, or too permissive/strict — these are
   illustrative per-field checks, not committed exact regexes; phase-2
   drafting will need to tune them against real proposal/record text.
2. Whether the intra-field Bullseye ordering check (candidate-list
   marker required alongside chosen-channel marker) is worth the added
   gate complexity, or whether it should be deferred to a future round
   once real usage shows whether sessions actually skip the
   brainstorm step in practice.
3. Whether `role-config.sh`'s deferred `RECORD_FIELDS_METHODOLOGY`
   extension (issue #1 §d, still blocked per issue #6's record) should
   be revisited alongside this issue's phase-2, now that this proposal
   shows the gate does not strictly require it — carried over from issue
   #1's open question 2, not resolved here.
