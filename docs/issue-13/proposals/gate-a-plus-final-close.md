# Issue #13 — Phase-1 Proposal: 게이트 A+ 최종 마감 (재감사 잔여 결함 보수)

Status: PROPOSAL — phase 1 only. Not an implementation. Waits for approvers.md APPROVE before phase 2 begins.

## Scope

Fix the five defects listed in the 2026-08-01 재감사 (grade B), plus matcher/code coverage parity, missing-core test coverage + compliance-check adoption, and README/manifest hygiene enforcement. Reference core's landed #75 pattern by source, never vendor a copy.

## 1. gate-lib 전면 이관

Each of `marketing-channel/hooks/channel-gate.sh`, `marketing-messaging/hooks/messaging-gate.sh`, `marketing-segment/hooks/segment-gate.sh`, and `marketing/hooks/directive.sh` converges on the guarded-source shape core #75 established (per `gate-house-standard.md`'s 5-step checklist):

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-${CLAUDE_PLUGIN_ROOT}/../core}/hooks/lib/gate-lib.sh" \
  || { echo "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }
```

- Replace each gate's hand-rolled kill-switch case statement with `gate_kill_switch_active`.
- Replace each gate's hand-rolled `Edit`/`MultiEdit` `.replace()` reconstruction with `gate_reconstruct_write` (or core's equivalent).
- Replace `marketing/hooks/directive.sh`'s unguarded `source .../role-directive.sh` with the guarded form; today's line has no `||` and fails open by construction — this is the highest-severity single fix in the set since it means the directive gate is currently a no-op whenever core isn't installed at runtime.
- `marketing/hooks/lib/role-config.sh`: retire, not wire-in. Its `RECORD_FIELDS_*` contract was written against an unverified `[ASSUMPTION]`-tagged guess at core's `record-fields-gate.sh` shape, predates core's actual landing, and is dead code today (nothing sources it). Wiring it into a contract nobody has confirmed risks shipping a second unverified guess under the same defect number. Delete the file and the corresponding `README.md:25` present-tense claim; if core's real record-fields-gate canon needs role config once actually integrated, that is new work scoped to whichever issue does that integration, with the real schema in hand.
- `docs/handbooks/gate-house-standard.md`'s checklist order is the execution order for phase 2: compliance-check (baseline, will show current FAILs) → migrate each gate → re-run adapted seven-case harness → compliance-check clean → this record.

Migration is by reference: gates source `gate-lib.sh` from `${CLAUDE_PLUGIN_ROOT_CORE}`, never a copied/vendored file in this repo.

## 2. vs.b 정규식 버그

`messaging-gate.sh:219`: change the cue pattern's literal-dot boundary from `vs\.\b` to a boundary that tolerates the standard "word. space" punctuation — e.g. `vs\.(?=\s|$)` (lookahead on whitespace/end instead of `\b` after a non-word char), or align with `segment-gate.sh:228`'s already-correct `(^|\s)vs(\.|\s|$)` shape for consistency across both gates. Either fix must be verified against both `'vs. Acme'` (must match) and `'vs.Acme'`/`'advs.'`-style false positives (must not spuriously match mid-word) before landing.

## 3. bare 'unlike' 통과

Tighten `messaging-gate.sh:225`'s `has_any(..., "unlike")` check for the unique-attributes requirement to require the same kind of proximity anchor `near()` already provides for competitive-alternatives, rather than an unanchored substring test. Concretely: treat "unlike"/"differentiat"/"unique attribute"/"only we" as a cue set and require `near(cue, anchor)` with an anchor that names an actual attribute or competitor token nearby — not just presence of the substring anywhere in the section. This also incidentally fixes the `"unlikely"` substring false-positive, since a real anchor requirement can't be satisfied by an unrelated word fragment.

## 4. near() 앵커 vacuous

Root cause: the anchor's second alternative (`[A-Z][a-zA-Z0-9]*(\s+[A-Z][a-zA-Z0-9]*)*`) is satisfiable by any sentence-initial capitalization in the window, because the window is scanned with unanchored `re.search` rather than requiring the capitalized token to sit adjacent to the cue itself. Fix direction: scope the anchor check to a fixed token distance from the cue's own match position (not the whole ±N-line window), and exclude matches where the candidate capitalized token is the first word of its sentence (a `(?<![.!?]\s)` negative lookbehind, or equivalent tokenization-based check) so ordinary sentence-initial capitals stop counting as a named alternative. Apply identically to both `messaging-gate.sh:203-210` and `segment-gate.sh:199-206` since the two copies are currently duplicated — this migration is also the natural point to move `near()` into a single shared helper (either core gate-lib, if it has an equivalent, or a small local shared file) instead of keeping two independently-maintainable copies that can drift again.

## 5. Coverage parity (Bash writes) + missing-core test + compliance-check

- Extend each methodology gate's `hooks.json` matcher from `Write|Edit|MultiEdit` to also include `Bash`, and extend each gate's Python dispatch to call `gate_bash_write_targets` (core #75's ported function) so a `Bash`-tool write (`cat >`, `tee`, `>>`) to a gated report path is caught identically to a `Write`/`Edit`/`MultiEdit` call. This closes the parity gap and is the concrete fix for defect 1's Bash-bypass finding.
- Add a `missing-core` case to `tests/run-gate-tests.sh` per group 7 of core's seven-group harness shape: set `CLAUDE_PLUGIN_ROOT_CORE` to a path that doesn't exist, run each gate, assert exit 2 / deny (fail-closed), not silent allow. Add one such case per gate (channel/messaging/segment) plus directive.sh, since each now sources gate-lib independently.
- Add a referenced (not vendored) invocation of core's `compliance-check.sh` against this repo's `hooks/` directories, run as part of the test suite or a documented separate step, with a clean-pass record captured in phase 2's delivery record — not in this proposal, since compliance-check can only meaningfully run post-migration.

## 6. README/manifest hygiene

Today's README/manifest are clean (verified in the survey) — the requirement is preventive and mechanical, not a cleanup of an existing violation:

- In the same commit that migration lands, update `README.md:33-38`'s "no core/ tree exists here yet" hedge to reflect the real state (core referenced by path, not vendored).
- Add a mechanical, hard-fail test (not manual grep) asserting each `.claude-plugin/plugin.json`'s `name` field equals its containing directory name, and a denylist check for any legacy role-name pattern the repo has ever used, so a future regression is caught in the suite rather than by re-audit. This directly satisfies the issue's "옛 이름은 하드 에러" requirement with an enforced check instead of a one-time manual pass.

## Sequencing (phase 2)

1. Baseline `compliance-check.sh` run against current gates (expected FAIL, recorded for before/after contrast).
2. Migrate `directive.sh` first (currently fail-open — highest severity), then the three methodology gates, in the gate-lib guarded-source shape.
3. Land fixes 2–4 (regex, anchor, near()) as part of the same gate-script edits, since they touch the same files being migrated.
4. Retire `role-config.sh` stub + README claim.
5. Add Bash coverage to matcher + `gate_bash_write_targets` calls.
6. Extend `tests/run-gate-tests.sh` with missing-core cases; re-run full suite green.
7. Re-run `compliance-check.sh` clean; add the manifest-name/legacy-name hard-fail test.
8. Update README hedge language; write phase-2 delivery record citing clean suite + clean compliance-check.

No implementation performed in this phase. Awaiting APPROVE per role-handoff contract v3 s19.
