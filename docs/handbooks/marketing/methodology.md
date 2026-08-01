# Marketing methodology plugin set — checklist

Worked guidance for `docs/issue-7/proposals/plugin-deepening-proposal.md`,
hardened per `docs/issue-10/proposals/gate-a-plus-hardening.md`.
The three plugin gates (`marketing-messaging/hooks/messaging-gate.sh`,
`marketing-channel/hooks/channel-gate.sh`,
`marketing-segment/hooks/segment-gate.sh`) enforce the mechanical minimum
below, each independently and fail-closed; this handbook is the reasoning
behind each line. Run `tests/run-gate-tests.sh` from repo root to exercise
all three gates as real subprocesses.

On an in-scope write (`docs/issue-<n>/proposals/*marketing*.md` or
`docs/issue-<n>/reports/marketing.md`), a missing section marker now
**denies** rather than silently passing — a marketing write surface must
carry its methodology field explicitly, even to say it is deferred. Once a
section is found, every check below is scoped to that section's own text
span (heading/marker to the next heading or EOF), not the whole document;
checks that key on a comparison word (e.g. "vs.") additionally require it
to sit near a list item or a named alternative, not stand alone.

## messaging doc — Dunford positioning canvas

1. **Competitive alternatives** named — the comparison is the point of the
   canvas; a value prop with no named alternative is a shortcut, not a
   positioning statement.
2. **Unique attributes** stated relative to those alternatives.
3. **Per-segment value proposition** — translated for the specific segment,
   not one generic sentence for everyone.
4. **Market category** named.
5. **One-line positioning statement** that is traceable back to (1), not
   merely present as boilerplate.

Kill switch: `MARKETING_MESSAGING_GATE_OFF=<1|true|yes|on>`. Any other
value — unset, empty, or unrecognized — leaves the gate active.

## channel plan — Bullseye 3-phase test

1. **Candidate channels** brainstormed broadly and listed.
2. **Test criteria/rationale** stated per candidate (cheap-test-first,
   not preference-first).
3. **Chosen channel** stated with its rationale.
4. **Owned/earned/paid** classification given — all three labels must
   each be attached to a listed channel (`label:`/`label-`/`(label)`), not
   merely mentioned once anywhere in the field; e.g. "paid social" as a
   candidate-channel name does not by itself satisfy the "paid" axis.
5. **Ordering**: a chosen channel can never appear without a visible
   candidate list in the same field — Bullseye's whole point is
   brainstorm-then-select, not select-then-justify. The gate enforces this
   as an intra-field structural check, not a persisted cross-record state.

Kill switch: `MARKETING_CHANNEL_GATE_OFF=<1|true|yes|on>`. Any other
value — unset, empty, or unrecognized — leaves the gate active.

## target segment — STP + ICP

1. **Segmentation criteria** named (demographic / firmographic /
   behavioral / psychographic).
2. **ICP defined concretely** — more than one criterion type, or an
   explicit `ICP:` block. A bare demographic label alone is not an ICP.
3. **Targeting rationale** stated against alternative segments — why this
   segment over the others, not just a description of the chosen one.

Kill switch: `MARKETING_SEGMENT_GATE_OFF=<1|true|yes|on>`. Any other
value — unset, empty, or unrecognized — leaves the gate active.

## Why this exists

Each gate checks only its own record field's section and is silent
(exit 0) on any write that doesn't touch it — the three plugins stay
independent per methodology, matching core's `freelunch`/`scout` shape
rather than one monolithic gate. This is the minimum that keeps a
`messaging doc`/`channel plan`/`target segment` write from silently
skipping the stage its named methodology requires, and strengthens
(never replaces) core canon's §20 record fields.
