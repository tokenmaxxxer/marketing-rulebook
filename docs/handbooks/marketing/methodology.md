# Marketing methodology plugin set — checklist

Worked guidance for `docs/issue-7/proposals/plugin-deepening-proposal.md`,
hardened per `docs/issue-10/proposals/gate-a-plus-hardening.md`, and
migrated onto core's landed gate-house standard per
`docs/issue-13/proposals/gate-a-plus-final-close.md`.
The three plugin gates (`marketing-messaging/hooks/messaging-gate.sh`,
`marketing-channel/hooks/channel-gate.sh`,
`marketing-segment/hooks/segment-gate.sh`), plus `marketing/hooks/directive.sh`,
enforce the mechanical minimum below, each independently and fail-closed;
this handbook is the reasoning behind each line. Run
`tests/run-gate-tests.sh` from repo root to exercise all three gates as
real subprocesses.

All four scripts source core's `gate-lib.sh`/`role-directive.sh` by
reference — `${CLAUDE_PLUGIN_ROOT_CORE:-${CLAUDE_PLUGIN_ROOT}/../core}`,
never vendored — with a guarded `|| { ...; exit 2; }` source line, so a
missing/unreachable core denies rather than silently no-ops. The three
gates' `hooks.json` matcher and Python dispatch also cover `Bash`-tool
writes (`gate_bash_write_targets`), not just `Write`/`Edit`/`MultiEdit`, so
a shell redirect into a gated path is caught the same way a tool call
would be.

On an in-scope write (`docs/issue-<n>/proposals/*marketing*.md` or
`docs/issue-<n>/reports/marketing.md`), a missing section marker now
**denies** rather than silently passing — a marketing write surface must
carry its methodology field explicitly, even to say it is deferred. Once a
section is found, every check below is scoped to that section's own text
span (heading/marker to the next heading or EOF), not the whole document;
checks that key on a comparison word (e.g. "vs.") additionally require it
to sit near a list item or a named alternative, not stand alone — the
anchor search is scoped to a fixed character window around the cue's own
match position and excludes ordinary sentence-initial capitalization, so a
bare cue with nothing actually named nearby no longer passes.

## messaging doc — Dunford positioning canvas

1. **Competitive alternatives** named — the comparison is the point of the
   canvas; a value prop with no named alternative is a shortcut, not a
   positioning statement.
2. **Unique attributes** stated relative to those alternatives — a bare
   occurrence of the cue word ("unlike", "differentiat-", "unique
   attributes", "only we") is not enough; it must sit near an actual named
   attribute or competitor, the same proximity requirement (1) already
   has, so it can't be satisfied by an unrelated word fragment (e.g.
   "unlikely").
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

`marketing/hooks/lib/role-config.sh`, a pre-core-landing stub for a
record-fields contract nothing ever consumed, was retired in issue #13;
role-record-fields config is core's canon to own once that integration is
actually scoped. `tests/run-gate-tests.sh` also mechanically enforces that
every `.claude-plugin/plugin.json`'s `name` equals its containing
directory name and that no legacy role-name pattern has reappeared,
instead of relying on a one-time manual grep.
