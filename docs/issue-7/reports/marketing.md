# Phase-2 record: plugin-set deepening for marketing methodology enforcement (issue #7)

Subject: issue-7. Phase-2 output (waits for the approver's APPROVE per
contract v3 s19). Approved via issue comment `APPROVE issue-7/marketing`
(JiwonJung94, listed in `docs/specs/approvers.md`), single-account mode.

## why

The prior single-gate/single-directive shape was rejected by the approver's
review comment on this PR (see the proposal's "요구 정정" and "Revision
note"): the requirement is per-methodology independence, one plugin per
adopted methodology, mirroring core's `freelunch`/`scout` shape — not a
monolithic `marketing/hooks/methodology-gate.sh`. This record reflects the
corrected shape as executed.

## what was done

Implemented the three new self-contained plugins specified in the approved
proposal (`docs/issue-7/proposals/plugin-deepening-proposal.md` §1–3),
plus the §4/§6/§7 orchestration changes to the existing `marketing` plugin:

- `marketing-messaging/` — Dunford positioning-canvas gate
  (`hooks/messaging-gate.sh`) and directive fragment for the `messaging doc`
  field. `plugin.json`, `hooks/hooks.json`, `README.md`.
- `marketing-channel/` — Bullseye 3-phase-test gate (`hooks/channel-gate.sh`,
  including the intra-field brainstorm-before-select ordering check) and
  directive fragment for the `channel plan` field. `plugin.json`,
  `hooks/hooks.json`, `README.md`.
- `marketing-segment/` — STP+ICP gate (`hooks/segment-gate.sh`) and
  directive fragment for the `target segment` field. `plugin.json`,
  `hooks/hooks.json`, `README.md`.
- `marketing/hooks/directive.sh` — trimmed to orchestration: sources the
  three plugins' `directive-fragment.sh` files (degrading gracefully to an
  empty fragment if a plugin is not installed) and concatenates them into
  one SessionStart directive, plus the phase-1 checklist block (issue #1
  §a) folded in per proposal §6/§9-open-question-2's decision (no fourth
  `marketing-checklist` plugin).
- `.claude-plugin/marketplace.json` — registered `marketing-messaging`,
  `marketing-channel`, `marketing-segment` alongside the existing
  `marketing` entry.
- `tests/run-gate-tests.sh` — repo-root shared test runner (mirrors
  `implementation-rulebook/tests/run-gate-tests.sh`'s subprocess-invocation
  shape), covering all three gates: allow-complete, deny-missing-element
  (including the channel plugin's ordering-violation case), allow-when-
  section-absent (gate is silent outside its own field), and
  allow-with-kill-switch, for each plugin.

Each gate is fail-closed (`trap __fc EXIT`), has its own kill switch
(`MARKETING_MESSAGING_GATE_OFF`, `MARKETING_CHANNEL_GATE_OFF`,
`MARKETING_SEGMENT_GATE_OFF`), and checks only its own record field's
section — none reference or depend on another field's content, matching
the proposal's per-methodology independence requirement.

`role-config.sh` was left unchanged, per proposal §8: none of the three
gates read `RECORD_FIELDS_METHODOLOGY`, so this deferral (carried over
from issue #1/#6) is not blocking.

## what did not work

Nothing blocking. The pricing-rulebook's `methodology-gate.sh` and the
implementation-rulebook's `tests/run-gate-tests.sh` were read for structural
shape only (fail-closed trap, kill-switch convention, JSON-payload
reconstruction, subprocess test-invocation format) — canon-scripts
"reference, don't copy": no marketing-specific content was copied from
either.

## open findings

Carried over from the approved proposal's open questions, none resolved by
this phase-2 execution since they are approver-facing design questions, not
implementation blockers:
- whether the three-way plugin split is the right granularity long-term;
- whether the phase-1 checklist should get its own plugin;
- whether the keyword/regex heuristics in each gate need tuning against
  real proposal/record text;
- whether the `marketing-channel` intra-field ordering check is worth its
  complexity;
- whether `role-config.sh`'s deferred extension should be revisited;
- whether `warrant` (core) should wrap phase-2 record writes.

## upstream basis

`docs/issue-7/proposals/plugin-deepening-proposal.md` (APPROVEd phase-1
proposal, the requirement-corrected plugin-set version) is the concrete
upstream basis for every action above.

## loop_state

loop_state: landed

All three plugins, orchestration changes, marketplace registration, and
the shared test suite are implemented and passing.
