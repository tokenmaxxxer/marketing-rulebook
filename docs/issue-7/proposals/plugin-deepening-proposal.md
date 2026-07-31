# Proposal: plugin-set deepening — enforcement mechanism for marketing's adopted methodology (issue #7)

Subject: issue-7

Status: Phase 1 proposal — NOT executed. Requires human APPROVE before
any task below is carried out (contract v3 s19). This document is a
design/spec for phase-2 implementation; no `marketing/hooks/*` file, no
new plugin directory, no `.claude-plugin/marketplace.json` edit, no
`tests/` file, and no `role-config.sh` edit is made by this PR.

Basis: `docs/issue-7/reports/marketing/survey.md` (current-state gap
survey), `docs/issue-7/reports/marketing/scout-brief.md` (hook-machine
rigor scouted from sibling rulebooks), and the previously APPROVEd
`docs/issue-1/proposals/rulebook-maturation.md` §b/§c (the methodology
norms this proposal enforces — referenced, not restated in full; see
that document for the source citations and rationale behind each
methodology choice). Structural precedent for the plugin-set SHAPE
(referenced by path only, structure not content — no marketing content
copied from it):
`/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/.claude-plugin/marketplace.json`,
which registers five independent single-concern plugins (`core`,
`terse`, `freelunch`, `scout`, `warrant`), each `<name>/.claude-plugin/
plugin.json` plus its own `hooks/` (and sometimes `agents/`/
`workflows/`) directory. Rigor precedent for individual gate/test file
shape (referenced by path only, content not copied per canon-scripts
"reference, don't copy"):
`/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`
and
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`.

## Revision note

This document replaces an earlier draft of the same proposal that
specified a single deepened `marketing/hooks/directive.sh` +
`marketing/hooks/methodology-gate.sh` pair covering all three record
fields. Per the approver's review comment on this PR, that shape was
rejected: the requirement is a **plugin set**, not a single gate/
directive deepening — each adopted methodology becomes an independent,
self-contained plugin (mirroring core's `freelunch`/`scout`), and both
the phase-1 (proposal-writing) and phase-2 (deliverable) norms must be
expressed as **compositions** of which plugins combine to constitute
each norm. This document is restructured accordingly. The underlying
technical content (directive facet text, per-field keyword checks, the
intra-field candidate-before-chosen ordering check, gate-test cases,
open questions) is preserved from the prior draft, relocated into the
plugin that owns it.

## 0. Design summary — the plugin set

Four plugins are proposed, three new and one existing:

| # | Plugin | Status | Methodology owned |
|---|---|---|---|
| 1 | `marketing` | existing, directive trimmed | none (orchestration/hand-off only) |
| 2 | `marketing-messaging` | **new** | Dunford positioning canvas — `messaging doc` field |
| 3 | `marketing-channel` | **new** | Bullseye 3-phase test — `channel plan` field |
| 4 | `marketing-segment` | **new** | STP + ICP — `target segment` field |

No `marketing-checklist` plugin is proposed as a separate unit (see §4
for the composition and the rationale for folding its function into
existing plugins instead of adding a fourth new one). Sections 1–4
specify each plugin's self-contained contents; section 5 shows the
plugin table required by the approver's comment (name / methodology /
components / combination); sections 6–7 show how phase-1 and phase-2
norms are each a **composition** of these plugins (plus core's
`scout`, and an explicit non-inclusion decision on core's `warrant`).

## 1. `marketing-messaging` plugin — Dunford positioning canvas

Scope: the `messaging doc` record field only. Self-contained: owns its
own directive fragment, its own gate, its own gate tests. Does not
reference or check `channel plan` or `target segment` content.

**Directory (phase-2, none created by this PR):**
```
marketing-messaging/.claude-plugin/plugin.json
marketing-messaging/hooks/hooks.json          <- PreToolUse -> messaging-gate.sh
marketing-messaging/hooks/messaging-gate.sh
marketing-messaging/hooks/directive-fragment.sh  <- sourced by marketing/hooks/directive.sh
```

**Directive fragment** (per issue #1 §b messaging-doc row, restated as
executable instruction — this is the PHASE-2 messaging-doc facet
content from the prior draft's section 1, unchanged in substance,
relocated here): named methodology (Dunford's competitive-alternatives-
first positioning canvas, *Obviously Awesome*, 2019); stages implicit
in the canvas (name competitive alternatives → name unique attributes →
translate to per-segment value prop → name market category → synthesize
one-line positioning statement); judgment criterion for "done" (a
one-line positioning statement exists AND is traceable to a named
competitive alternative, not merely present); prohibition (a generic,
unattributed value-prop sentence with no named alternative is a
prohibited shortcut — the whole point of Dunford's canvas is the
comparison).

**Gate** (`messaging-gate.sh`, mirroring pricing's
`methodology-gate.sh` structurally — rigor reference only, marketing-
specific checks):
- Fail-closed `trap __fc EXIT` installed as the first statement.
- Kill switch: `export MARKETING_MESSAGING_GATE_OFF=1`.
- Write-surface regex: `^docs/issue-[0-9]+/proposals/.*marketing.*\.md$`
  and `^docs/issue-[0-9]+/reports/marketing\.md$`, but unlike the prior
  single-gate draft this gate additionally requires a `messaging doc`
  (or equivalent) section marker be present in the reconstructed
  content before it runs any check — silent (`exit 0`) if the write
  touches the record file but not the messaging-doc section, silent on
  any other path per pricing's "not this gate's business" pattern.
- Content reconstruction for `Write`/`Edit`/`MultiEdit`; deny if the
  resulting text cannot be determined from the tool-call payload.
- Required-element keyword/regex checks (identical set to the prior
  draft's messaging-doc table row, unchanged): competitive-alternatives
  language present; unique-attributes language present; per-segment
  value-prop language (word "segment" co-occurring with "value prop"/
  "benefit", not one generic sentence); market-category language; a
  one-line positioning-statement marker.
- Denial message names exactly which element(s) are missing and cites
  `docs/issue-1/proposals/rulebook-maturation.md` §b (messaging doc row)
  as the norm source.

**Gate tests** (repo-root `tests/run-gate-tests.sh`, this plugin's
cases only, subprocess-invocation shape mirroring
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`):
- `allow`: a `Write` to `docs/issue-<n>/proposals/marketing-x.md`
  containing all five messaging-doc elements -> exit 0.
- `deny`: same target, missing competitive-alternatives language -> exit
  2, message names `competitive-alternatives` as missing.
- `allow`: write to an unrelated path or a record write with no
  messaging-doc section -> exit 0 (gate silent).
- `deny`: malformed/unparseable JSON payload -> exit 2 (fail-closed).
- `allow`: `MARKETING_MESSAGING_GATE_OFF=1` set -> exit 0 regardless of
  content.

## 2. `marketing-channel` plugin — Bullseye 3-phase test

Scope: the `channel plan` record field only. Self-contained, same
shape as §1. This plugin also owns the **intra-field ordering check**
that was filed under "State tracking" in the prior single-gate draft:
that check is intrinsic to Bullseye specifically (its own "brainstorm
before select" shape, issue #1 §b), not a shared cross-plugin
mechanism, so it lives entirely inside this plugin's gate rather than
in any shared or orchestrating code.

**Directory (phase-2, none created by this PR):**
```
marketing-channel/.claude-plugin/plugin.json
marketing-channel/hooks/hooks.json          <- PreToolUse -> channel-gate.sh
marketing-channel/hooks/channel-gate.sh
marketing-channel/hooks/directive-fragment.sh
```

**Directive fragment**: named methodology (Bullseye Framework's 3-phase
test, Weinberg & Mares, *Traction*, 2015); ordered stages (brainstorm
candidates broadly → cheap-test each → select with rationale);
judgment criterion for "done" (a chosen channel exists with a stated
test rationale AND a visible candidate list in the same field);
prohibition (selecting a channel without a stated test rationale is a
prohibited shortcut — Bullseye's whole point is test-before-commit, not
pre-existing preference).

**Gate** (`channel-gate.sh`), same fail-closed/kill-switch/write-
surface/content-reconstruction shape as §1, scoped to the `channel
plan` section only:
- Kill switch: `export MARKETING_CHANNEL_GATE_OFF=1`.
- Required elements (identical set to the prior draft's channel-plan
  table row): candidate-channel list (plural-channel-name heuristic or
  explicit "candidates:" marker); test-criteria/rationale language
  ("test", "criteria", or "rationale" present per candidate context);
  chosen-channel-with-rationale marker; owned/earned/paid classification
  keywords.
- **Intra-field ordering check** (relocated verbatim in substance from
  the prior draft's "State tracking" subsection): within the field's
  current text, a candidate-list marker must exist whenever a
  chosen-channel marker exists — a document cannot show a "chosen
  channel" section without also showing a "candidates considered"
  section in the same text. This remains a same-document structural
  check, not a persisted state file, because both Bullseye stages live
  in one field's content by design (issue #1 §b lists both as mandatory
  components of the same `channel plan` field). No `state.sh`-style
  file or `loop_state` cross-record tracking is proposed for this
  plugin or any other in this set, since none of the three adopted
  methodologies spans multiple record files or roles the way coding's
  verify-then-resolve cycle does (per the scout-brief's "one pattern to
  skip"). If a future methodology round introduces a genuine cross-role
  or cross-record ordering constraint, that would warrant a
  coding-style `loop_state` pattern in a future plugin — not proposed
  here.
- Denial message cites `docs/issue-1/proposals/rulebook-maturation.md`
  §b (channel plan row).

**Gate tests**:
- `allow`: complete channel-plan section (candidates + test-criteria +
  chosen + rationale + owned/earned/paid) -> exit 0.
- `deny`: chosen-channel marker present, no candidate-list marker ->
  exit 2 (intra-field ordering check).
- `deny`: missing owned/earned/paid classification -> exit 2.
- `allow`: unrelated path, or record write with no channel-plan section
  -> exit 0.
- `allow`: `MARKETING_CHANNEL_GATE_OFF=1` set -> exit 0.

## 3. `marketing-segment` plugin — STP + ICP

Scope: the `target segment` record field only. Self-contained, same
shape as §1–2.

**Directory (phase-2, none created by this PR):**
```
marketing-segment/.claude-plugin/plugin.json
marketing-segment/hooks/hooks.json          <- PreToolUse -> segment-gate.sh
marketing-segment/hooks/segment-gate.sh
marketing-segment/hooks/directive-fragment.sh
```

**Directive fragment**: named methodology (STP + ICP, Kotler & Keller
*Marketing Management*; standard B2B/B2C ICP practice; JTBD as optional
behavioral lens per issue #1 §b); stages (name segmentation criteria
used → define ICP concretely → state targeting rationale against
alternative segments); judgment criterion for "done" (ICP definition is
a concrete profile, not a bare demographic label — checked by requiring
more than one criterion type or an explicit "ICP:" block); prohibition
(a demographic label alone, with no rationale for why this segment over
others, is a prohibited shortcut).

**Gate** (`segment-gate.sh`), same shape:
- Kill switch: `export MARKETING_SEGMENT_GATE_OFF=1`.
- Required elements (identical set to the prior draft's target-segment
  table row): segmentation-criteria naming (at least one of
  demographic/firmographic/behavioral/psychographic); ICP-definition
  marker (more than one criterion type, or explicit "ICP:" block);
  targeting-rationale language ("why this segment", "over", "rather
  than").
- Denial message cites `docs/issue-1/proposals/rulebook-maturation.md`
  §b (target segment row).

**Gate tests**:
- `allow`: target-segment section with all three elements -> exit 0.
- `deny`: ICP marker reduced to a bare demographic label -> exit 2.
- `deny`: no targeting-rationale language -> exit 2.
- `allow`: unrelated path, or record write with no target-segment
  section -> exit 0.
- `allow`: `MARKETING_SEGMENT_GATE_OFF=1` set -> exit 0.

## 4. `marketing` plugin (existing) — trimmed to orchestration only

`marketing/hooks/directive.sh` is NOT deepened with all three
methodologies' facet text (that content moved to §1–3's directive
fragments, each sourced/concatenated by `marketing/hooks/directive.sh`
at SessionStart, matching how the sibling marketplace composes core's
shared machinery alongside role-specific plugins). What remains owned
by `marketing` itself:
- The PHASE 1 facet (proposal-writing norms, issue #1 §a) — see §6.
- Orchestration: sourcing/concatenating the three methodology plugins'
  directive fragments into one SessionStart output, so a session still
  sees one coherent directive even though the content is now
  plugin-owned.
- `write_scope: []` and hand-off-to-`growth-analytics` framing —
  unchanged from today.
- `marketing/hooks/lib/role-config.sh` — unchanged; see §8 for the
  carried-over deferral.

No `marketing-checklist` plugin is proposed as a fourth new unit. The
prior draft's §4 ("Supporting agents/checklists") proposed a
`MARKETING_CHECKLIST.md` reference block surfaced by the directive so
sessions see requirements before any gate would deny. That function is
preserved, but folded into the existing `marketing` plugin's directive
fragment (a PHASE-1-facet-adjacent checklist block, not a fourth
plugin) rather than split out: the checklist has no independent
methodology of its own — it is a restatement of the same
mandatory-component lists §1–3's gates already check mechanically — so
giving it a separate plugin would not satisfy the approver's "one
methodology, one plugin" requirement (there is no fourth methodology to
own). This is flagged as an open question in §9 in case the approver
disagrees with folding it in.

## 5. Plugin table (required)

| Plugin | Methodology owned | Directive fragment | Gate | Agent | Tests | Combines into |
|---|---|---|---|---|---|---|
| `marketing` | none (orchestration) | yes (PHASE-1 facet + fragment concatenation + checklist block) | no | no | no | phase-1 norm; phase-2 norm (orchestrator role) |
| `marketing-messaging` | Dunford positioning canvas | yes | yes (`messaging-gate.sh`) | no | yes | phase-2 norm |
| `marketing-channel` | Bullseye 3-phase | yes | yes (`channel-gate.sh`, incl. intra-field ordering check) | no | yes | phase-2 norm |
| `marketing-segment` | STP + ICP | yes | yes (`segment-gate.sh`) | no | yes | phase-2 norm |
| `scout` (core, existing) | — (research protocol, not a marketing methodology) | n/a (own plugin, referenced not vendored) | n/a | n/a | n/a | phase-1 norm |
| `warrant` (core, existing) | — | — | — | — | — | **excluded**, see §7 |

No agent (`agents/`) is proposed for any of the four marketing-owned
plugins, carrying forward the prior draft's §4 rationale: the three
methodologies are single-session, single-role deliverables (issue #1
§c: "rigor proportionate to a produces-only, `write_scope: []` role"),
not a repeated multi-step procedure spanning tool invocations the way a
warrant-hunter's repeated probing does.

## 6. Phase-1 norm (기획서 규범) as a plugin composition

The phase-1 proposal-writing norm (issue #1 §a: problem/goal statement,
current-state survey reference, named methodology citation,
required-sections checklist, evidence-citation, `[ASSUMPTION]`
flagging, status header) is **not** given its own new plugin. It is
shown here as the composition of two existing/retained plugins:

- **`marketing`** (this rulebook's own plugin, directive PHASE-1 facet,
  unchanged in substance from the prior draft's section 1 PHASE-1-facet
  text): supplies the marketing-specific instance of the norm — stages,
  judgment criteria (an "evidence-cited" claim points to a named
  external framework/source or an internal artifact this repo already
  has), and prohibitions (no skipping the survey-reference step; no
  presenting `[ASSUMPTION]`-worthy content as confirmed fact) — as
  directive text read at SessionStart.
- **`scout`** (core, already registered in
  `tokenmaxxxer-core/.claude-plugin/marketplace.json`, referenced not
  vendored): supplies the survey-first requirement's *procedural*
  backing — "bounded best-in-class reconnaissance with a saturation
  stop rule, compressed into a scout brief that feeds the role's
  proposal" per its own marketplace description. `docs/issue-7/reports/
  marketing/survey.md` and `scout-brief.md` are this rulebook's
  instances of exactly that protocol; the phase-1 norm's requirement #2
  (current-state survey reference) is `marketing`'s directive text
  citing an artifact that `scout`'s protocol is what actually produces.

No third plugin is required for phase-1: the checklist requirement
(issue #1 §a.4) is text-only guidance for a human/session, not a
machine-checked write surface the way phase-2's record fields are (no
gate enforces phase-1 document structure in either the prior draft or
this one) — so it stays inside `marketing`'s directive fragment rather
than warranting new gate machinery.

## 7. Phase-2 norm (산출물 규범) as a plugin composition

The phase-2 deliverable norm (issue #1 §b: the three record fields,
each machine-verified against its mandatory components) is the
composition of:

- **`marketing-messaging`** — gates `messaging doc` (§1).
- **`marketing-channel`** — gates `channel plan` (§2).
- **`marketing-segment`** — gates `target segment` (§3).
- **`marketing`** — orchestrates: SessionStart directive concatenation
  of all three fragments, `write_scope: []` boundary (unchanged),
  hand-off framing to `growth-analytics` (unchanged). `marketing`
  itself installs no `PreToolUse` gate of its own for phase-2 content —
  each field's gate is owned entirely by its methodology plugin, so a
  record write is checked by whichever of the three plugin gates
  matches the section present in the write, independently, with no
  shared gate logic to keep them decoupled per methodology.

**`warrant` (core) — explicitly excluded.** `warrant`'s marketplace
description is "the work-unit protocol for every role session: one
approval gate at the front, then uninterrupted execution inside a
frozen write set, with a diff-size-proportional, adaptively-bounded
hunt dispatched at proposal and landing." This is a *session-scoped*
work-unit/approval-gate protocol (applies to how a session's overall
turn is bounded and hunted), not a per-field content-methodology check.
None of `warrant`'s described mechanics (frozen write set, proposal/
landing hunt) map onto what §1–3's gates do (per-write keyword/element
verification against a named marketing methodology). `[ASSUMPTION]`
`warrant` may already apply generically to every role session
regardless of this proposal (its description says "every tokenmaxxxer
role enables alongside its own rulebook" is `core`'s framing, and
`warrant` says "role rulebooks reference it rather than vendoring a
copy") — if so, it is orthogonal infrastructure this proposal neither
needs to invoke nor duplicate. This proposal does not force-fit
`warrant` into the phase-2 composition; it is named here only to record
that it was checked and found not clearly relevant, per the task
instruction to make that check explicit.

## 8. `role-config.sh` (carried over, unchanged decision)

Per issue #6's still-open deferral (`docs/issue-1/reports/
marketing.md`: `loop_state: blocked-on-external`, blocked on issue-2's
`stub-check.sh` verification gap against real core), this proposal does
**not** commit to extending `RECORD_FIELDS_REQUIRED`/
`RECORD_FIELDS_METHODOLOGY` in `role-config.sh` as part of phase-2
execution, for any of the three new plugins. `[ASSUMPTION]` each of
`marketing-messaging`/`marketing-channel`/`marketing-segment`'s gates
work independently of `role-config.sh` (each hardcodes its own regex/
keyword checks, as pricing's gate does, rather than reading role-
config), so all three plugins can be implemented without first
resolving that deferred structural edit. Whether `role-config.sh`
should still be extended once the verification gap closes remains an
open question for the approver (carried over from issue #1's own open
question 2), not resolved here.

## 9. Sequencing and constraints

- Canon scripts (core's `role-directive.sh`, any shared gate library)
  are referenced only, never copied, per core `canon-scripts.md`
  (referenced by path convention; not present as a checked-out file in
  this environment — `[ASSUMPTION]` this constraint's exact file
  location, consistent with how `docs/issue-1/proposals/
  rulebook-maturation.md` already treats core-canon references it
  cannot locally verify).
- `write_scope: []` and role boundaries are unchanged by this proposal;
  the three new gates only add mechanical enforcement over marketing's
  own existing write surface (its own proposals and its own record),
  none expand what marketing may write.
- Each new plugin requires its own `.claude-plugin/plugin.json` and a
  new entry in this repo's `.claude-plugin/marketplace.json` alongside
  the existing `marketing` entry (illustrative, phase-2 drafting, not
  created by this PR):

```json
{
  "name": "marketing-messaging",
  "source": "./marketing-messaging",
  "description": "Dunford positioning-canvas methodology gate and directive fragment for marketing's messaging-doc record field."
},
{
  "name": "marketing-channel",
  "source": "./marketing-channel",
  "description": "Bullseye 3-phase-test methodology gate and directive fragment for marketing's channel-plan record field, including the intra-field brainstorm-before-select ordering check."
},
{
  "name": "marketing-segment",
  "source": "./marketing-segment",
  "description": "STP+ICP methodology gate and directive fragment for marketing's target-segment record field."
}
```

- This proposal's phase-2 execution requires: (1) human APPROVE of this
  document (contract v3 s19), and (2) no additional cross-repo
  dependency for any of the three new plugins — unlike issue #1's
  phase-2, none of these gates require `role-config.sh` changes or
  issue-2's verification-gap closure, since each plugin's gate
  hardcodes its own checks rather than reading role-config.

## Open questions for the approver

1. Whether the three-way plugin split (`marketing-messaging`/
   `marketing-channel`/`marketing-segment`) is the right granularity,
   or whether a single combined plugin covering all three fields would
   be preferable for operational simplicity — this proposal reads the
   approver's comment as requiring per-methodology independence, but
   flags the trade-off explicitly since three plugins means three
   `plugin.json`s, three `hooks.json`s, and three gate scripts to
   maintain in lockstep with any future changes to
   `docs/issue-1/proposals/rulebook-maturation.md` §b.
2. Whether the phase-1 checklist function (issue #1 §a.4) should stay
   folded into `marketing`'s own directive fragment (§6, this
   proposal's choice) or be split into a dedicated `marketing-checklist`
   plugin as the task brief's phrasing contemplated — this proposal
   argues against a fourth plugin because the checklist has no
   independent methodology to own, but the approver may weigh the
   "one plugin per concern" principle differently.
3. Whether the keyword/regex heuristics sketched in each plugin's gate
   (§1–3) are the right granularity, or too permissive/strict — these
   remain illustrative per-field checks, not committed exact regexes;
   phase-2 drafting will need to tune them against real proposal/record
   text, same caveat as the prior draft.
4. Whether the intra-field Bullseye ordering check inside
   `marketing-channel` (§2) is worth the added gate complexity, or
   whether it should be deferred to a future round once real usage
   shows whether sessions actually skip the brainstorm step in
   practice — carried over from the prior draft's open question 2.
5. Whether `role-config.sh`'s deferred `RECORD_FIELDS_METHODOLOGY`
   extension (issue #1 §d, still blocked per issue #6's record) should
   be revisited alongside this issue's phase-2, now that this proposal
   shows none of the three gates strictly require it — carried over
   from issue #1's own open question 2, not resolved here.
6. Whether `warrant` (core) is correctly excluded from the phase-2
   composition (§7) or whether its proposal/landing hunt should in fact
   wrap phase-2 record writes — this proposal's read is that `warrant`
   is session-scoped work-unit infrastructure orthogonal to per-field
   content checks, but the approver may see a role for it this document
   missed.
