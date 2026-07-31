# Issue #1 — Current-State Survey (Phase 1)

Subject: issue-1

Status: Phase 1 (research/survey). No files touched outside
`docs/issue-1/`, no gates changed. This document records what this repo
already has today so the phase-1 proposal (`docs/issue-1/proposals/
rulebook-maturation.md`) has a concrete baseline instead of assuming a
blank slate.

## 1. What exists today: directive and record-field norms

`marketing/hooks/directive.sh` (thin stub over core's
`core_role_directive`, per issue-2) declares:

- `PRODUCES (required record fields): messaging doc, channel plan, target segment`
- `WRITE_SCOPE: []`
- `HAND-OFF: 퍼널 성과 해석은 → growth-analytics`

`marketing/hooks/lib/role-config.sh` mirrors this mechanically:

```
RECORD_FIELDS_REQUIRED=("messaging-doc" "channel-plan" "target-segment")
RECORD_FIELDS_RECORD_PATH="reports/marketing.md"
RECORD_FIELDS_TERMINAL_STATES=()
```

That file carries its own `[ASSUMPTION]` flag: it is "currently unused
pending core's actual gate-canon wiring" — core was not discoverable in
this environment when issue-2's phase-2 landed. So today, the record-
fields gate (wherever it actually lives — core canon per issue-2, not a
role-local script) can at most check **field presence** in
`docs/issue-<n>/reports/marketing.md`. It has no way to check field
*structure* or *methodology* — there is no schema, no required
sub-components, no citation requirement, nothing beyond "does a heading
or key named `messaging-doc` exist."

## 2. What's missing: no phase-1 proposal precedent for this issue

`README.md` documents `decides`/`use_when`/`produces`/`write_scope`/
`hand-off` at the plugin level but says nothing about how a *phase-1
proposal* for this role should be structured, what evidentiary bar it
must clear, or what methodology it should draw on. This repo has never
had a phase-1 proposal specifically about *this role's own deliverable
methodology* before — the only phase-1 proposal precedent in this repo is
`docs/issue-2/proposals/core-canon-migration.md`, which is an
infrastructure-migration proposal (gates/hunt-agent → core canon
references), not a domain-methodology proposal. It is useful as a
**structural** precedent (status line, ordering-constraint section,
`[ASSUMPTION]` flagging, summary table) but has nothing to say about
marketing methodology itself.

## 3. Sibling issue-2: ordering constraint

`docs/issue-2/proposals/core-canon-migration.md` (APPROVEd and executed
per `docs/issue-2/reports/implementation.md`) migrated three gate scripts
and the hunt agent from role-local copies to core-canon references, and
introduced `marketing/hooks/lib/role-config.sh` as the (currently unused)
home for record-field config, "pending core's actual gate-canon wiring."

Per issue-2's own proposal text: *"this migration must land before this
repo's 'rulebook maturation' issue reaches its own phase 2"* — i.e.,
**this issue's (issue-1's) phase 2 must be sequenced after issue-2's
phase 2.** Issue-2's phase 2 has already landed (`implementation.md`
shows `loop_state: blocked-on-external`, file-level migration complete,
but `stub-check.sh` verification against real core still open). So issue-
1's phase-2 execution is not yet fully unblocked: it should not assume
`role-config.sh`'s current shape/consumption-point is final, since issue-
2's own open findings say the real core gate-canon contract for that file
is still unverified. Issue-1's phase-2 proposal (see the maturation
proposal's "plugin reflection plan") accounts for this by treating its
own `role-config.sh` edits as contingent on issue-2's remaining
verification work, not as free of it.

## 4. What phase-2 record norms exist today (methodology gap)

Summary: the three record fields (`messaging-doc`, `channel-plan`,
`target-segment`) exist only as **names**. There is:

- No stated methodology for building a messaging doc (no positioning
  framework, no competitive-alternatives requirement, no named
  methodology at all).
- No stated methodology for building a channel plan (no channel-
  selection framework, no owned/earned/paid taxonomy, no test-before-
  commit discipline).
- No stated methodology for defining a target segment (no segmentation
  criteria, no ICP concept, no targeting rationale requirement).
- No evidence/citation norm for any of the three (a bare assertion would
  currently satisfy the mechanical presence check).
- No connection specified between the fields and the role's hand-off
  partner (`growth-analytics`) — e.g. no requirement that channel-plan or
  target-segment carry measurable/falsifiable success criteria that
  growth-analytics could pick up cleanly.

This is the gap `docs/issue-1/reports/marketing/scout-brief.md` and
`docs/issue-1/proposals/rulebook-maturation.md` address.

## 5. Summary table

| Norm | Exists today? | Detail |
|---|---|---|
| Phase-1 proposal methodology (for domain-methodology proposals) | No | Only structural precedent from issue-2's infra-migration proposal |
| Record field *names* | Yes | `messaging-doc`, `channel-plan`, `target-segment` (directive.sh, role-config.sh) |
| Record field *methodology* | No | Names only, no required structure/method |
| Record field *evidence norm* | No | Nothing requires substantiation beyond presence |
| Mechanical gate capability | Presence-check only | Per issue-2 survey; structure-checking is not implemented anywhere |
| Ordering constraint vs. issue-2 | Yes, documented | issue-1 phase-2 must sequence after issue-2 phase-2 (per issue-2's own proposal text); issue-2 phase-2 has landed but has open verification gaps affecting `role-config.sh` |
