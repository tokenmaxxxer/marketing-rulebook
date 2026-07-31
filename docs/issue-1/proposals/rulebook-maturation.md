# Proposal: Rulebook maturation — phase-1 and phase-2 norms (issue #1)

Subject: issue-1

Status: Phase 1 proposal — NOT executed. Requires human APPROVE before any
task below is carried out (contract v3 s19). This document proposes
methodology and required sections for future phase-1 proposals in this
rulebook, and methodology/required components for the three phase-2
record fields. Execution (editing `directive.sh` / `role-config.sh`, or
any plugin file) is out of scope for this PR.

Basis: `docs/issue-1/reports/marketing/survey.md` (current-state survey)
and `docs/issue-1/reports/marketing/scout-brief.md` (domain-methodology
research). Structural precedent for this document's shape:
`docs/issue-2/proposals/core-canon-migration.md`.

## Ordering constraint

Per issue-2's own proposal text, issue-2's core-canon migration must land
before this issue's phase 2. Issue-2's phase 2 has landed
(`docs/issue-2/reports/implementation.md`), but with an open verification
gap: `stub-check.sh` has not been run against real core, and
`marketing/hooks/lib/role-config.sh`'s actual consumption point by core's
gate canon is unconfirmed (`[ASSUMPTION]` in that file). **This issue's
phase-2 execution must therefore also sequence after issue-2's remaining
verification work closes**, not just after issue-2's phase-2 commit
landed — editing `role-config.sh` further before its real consumption
contract is confirmed risks compounding an already-open assumption. This
proposal's plugin reflection plan (section d) treats this explicitly.

## (a) Phase-1 proposal norms (methodology for future phase-1 docs)

Future phase-1 proposals in this rulebook must include, at minimum:

1. **Problem/goal statement** — one paragraph, what decision or gap this
   proposal resolves.
2. **Current-state survey reference** — a companion survey doc (as this
   issue's `docs/issue-1/reports/marketing/survey.md` does) documenting
   what exists today before proposing change; a proposal without a survey
   reference is not adequate evidentiary basis.
3. **Methodology chosen, named** — any adopted methodology must cite a
   named framework/author/source (mirroring the scout-brief's citation
   style), not an unattributed "best practice."
4. **Required-sections checklist** — an explicit list of what the
   resulting phase-2 deliverable(s) must contain (see section (b) below
   for this issue's own instance of that checklist).
5. **Evidence-citation requirement** — every substantive claim in the
   proposal must be traceable to either (i) a named external
   framework/source, or (ii) an internal artifact this repo already has
   (survey findings, existing file contents). Bare assertion is not
   adequate basis, mirroring the evidence norm the scout-brief found
   across every surveyed marketing framework (section "Adopt/skip
   decisions" and "Gap line").
6. **`[ASSUMPTION]` flagging** — any claim resting on something not
   directly verifiable in this environment must be marked
   `[ASSUMPTION]` inline, exactly as `docs/issue-2/proposals/
   core-canon-migration.md` does throughout (e.g. its Task 1, Task 3,
   Task 4 sections). This is adopted as binding precedent, not just a
   stylistic choice: it keeps unverified claims visibly separate from
   confirmed ones so a future executor knows what to re-check.
7. **Status header line** — `Status: Phase 1 proposal — NOT executed.
   Requires human APPROVE ...`, matching contract v3 s19 gating.

## (b) Phase-2 deliverable norms

### messaging doc

Methodology: **April Dunford's competitive-alternatives-first positioning
canvas** (Source: *Obviously Awesome*, 2019). Chosen over StoryBrand
because it directly forces the comparison this role's decision boundary
requires ("which message" implies "message vs. what alternative");
StoryBrand may be referenced as an optional narrative/copywriting pass
but is not the required method (see scout-brief, "Adopt / skip
decisions").

Mandatory components:
- Competitive alternatives (what the customer would do/use instead)
- Unique attributes (what this offering has that alternatives don't)
- Value proposition per segment (translated from attributes to benefit,
  per segment — not one generic value prop)
- Market category (the frame the offering is positioned within)
- One-line positioning statement (synthesis of the above)

### channel plan

Methodology: **Bullseye Framework's 3-phase test** (Source: Weinberg &
Mares, *Traction*, 2015).

Mandatory components:
- Candidate channel list (brainstormed broadly, not pre-filtered to one)
- Test criteria/rationale (why these candidates, what cheap test
  validates each)
- Chosen channel(s) with rationale (post-test selection, not pre-test
  preference)
- Owned/earned/paid classification per candidate and chosen channel

### target segment

Methodology: **STP (Segmentation-Targeting-Positioning) + ICP** (Source:
Kotler & Keller, *Marketing Management*, STP model; standard B2B/B2C ICP
practice), with JTBD as an optional behavioral-criterion lens (Source:
Christensen/Moesta/Ulwick Jobs-to-be-Done literature).

Mandatory components:
- Segmentation criteria used (which of
  demographic/firmographic/behavioral/psychographic were applied)
- ICP definition (concrete profile, not a demographic label alone)
- Targeting rationale (why this segment over the other candidate
  segments considered)

## (c) Rationale — why these methodologies fit this role

This role's declared decision boundary is "어떤 메시지로 어떤 채널에
도달할지" (which message to which channel), with `write_scope: []` and
hand-off to `growth-analytics` for funnel-performance interpretation.
Each adopted methodology is argued against that boundary:

- **Dunford's canvas** is chosen because the decision is inherently
  comparative (message *relative to* alternatives) — a framework that
  does not force naming alternatives (e.g. a generic value-prop template)
  would let the messaging doc satisfy the field without actually
  resolving the decision this role owns.
- **Bullseye** is chosen because its 3-phase structure (brainstorm → cheap
  test → focus) matches a role that plans and tests but does not
  implement (`write_scope: []`) — it never requires this role to build
  or own channel infrastructure, only to select and justify. Its
  test-then-commit shape is also the natural upstream of growth-
  analytics's job: a channel plan built this way hands off a specific,
  bounded claim ("channel X won phase-2 testing on metric Y") that
  growth-analytics can verify/interpret, rather than an unfalsifiable
  preference.
- **STP + ICP** is chosen because it is the minimum-rigor, industry-
  standard method that still forces an explicit, falsifiable targeting
  rationale ("why this segment, not that one") — proportionate to a
  planning-only role rather than requiring, e.g., full quantitative
  market-sizing research that would belong to a different role's scope.
- Across all three, the shared design constraint is: **rigor
  proportionate to a produces-only, write_scope:[] role**, and **outputs
  structured so growth-analytics's hand-off is clean** — each mandatory-
  components list above includes at least one falsifiable/measurable
  element (chosen channel with test rationale; ICP with concrete
  criteria; positioning statement tied to named alternatives) rather than
  an unstructured narrative field.

## (d) Plugin reflection plan (phase-2, NOT executed now)

This section sketches what phase-2 execution of this proposal (after
APPROVE, and after issue-2's remaining verification work closes per the
ordering constraint above) would change. No file listed here is edited by
this PR.

**`marketing/hooks/directive.sh`**: update the `PRODUCES` line to add a
methodology pointer per field, e.g.:

```
PRODUCES (required record fields):
  messaging doc (positioning canvas — see docs/issue-1/proposals/rulebook-maturation.md §b),
  channel plan (Bullseye 3-phase test — see same),
  target segment (STP + ICP — see same)
```

The exact heredoc text is a phase-2 drafting decision, not fixed here;
this is a sketch of intent, not final wording.

**`marketing/hooks/lib/role-config.sh`** (or wherever core's
record-fields-gate canon actually reads role config, per issue-2's
still-open migration): today this file only carries
`RECORD_FIELDS_REQUIRED` as a flat list of field names. To satisfy the
record-fields gate once it can check structure rather than only
presence, each field would need an associated methodology note and
possibly a sub-field checklist, e.g. (illustrative, not a commitment to
this exact shape):

```bash
RECORD_FIELDS_REQUIRED=("messaging-doc" "channel-plan" "target-segment")
RECORD_FIELDS_METHODOLOGY=(
  "messaging-doc:dunford-positioning-canvas"
  "channel-plan:bullseye-3-phase"
  "target-segment:stp-icp"
)
```

`[ASSUMPTION]` this shape assumes core's gate canon will eventually
support a per-field methodology tag; **this is aspirational, not a claim
about current mechanical capability**. Per `docs/issue-2/reports/
implementation/survey.md`, the gate today only checks field *presence*
in the record body — it has no structure-checking capability at all.
Any structure/methodology enforcement is future work contingent on core
canon adding that capability; this proposal does not claim it exists or
will exist automatically.

**Sequencing**: this proposal's own phase-2 execution must happen after
(1) human APPROVE of this document, and (2) issue-2's remaining
verification gap (`stub-check.sh` against real core, and confirmation of
`role-config.sh`'s actual consumption point) is closed — editing
`role-config.sh` on top of an already-`[ASSUMPTION]`-flagged, unconfirmed
consumption point would compound risk rather than reduce it.

## Summary table

| Field | Methodology | Source | Mandatory components |
|---|---|---|---|
| messaging doc | Positioning canvas | Dunford, *Obviously Awesome* (2019) | competitive alternatives, unique attributes, value prop per segment, market category, one-line positioning statement |
| channel plan | Bullseye 3-phase test | Weinberg & Mares, *Traction* (2015) | candidate list, test criteria/rationale, chosen channel(s) + rationale, owned/earned/paid classification |
| target segment | STP + ICP | Kotler & Keller; standard ICP practice | segmentation criteria, ICP definition, targeting rationale |

## Open questions for the approver

1. Whether StoryBrand should be documented as a formally optional
   secondary pass for messaging doc, or left out of the rulebook
   entirely (this proposal leaves it as an unmandated reference only).
2. Whether the `RECORD_FIELDS_METHODOLOGY` shape sketched in (d) is the
   right eventual data structure, or whether core canon will define its
   own convention this rulebook must instead adapt to once discoverable.
3. Confirm the ordering constraint (issue-2 verification-gap closure)
   before scheduling this proposal's own phase-2 execution.
