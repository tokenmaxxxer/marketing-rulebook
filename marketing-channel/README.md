# marketing-channel

Methodology gate for marketing's `channel plan` record field.

## Methodology owned

The Bullseye Framework's 3-phase test (Gabriel Weinberg & Justin Mares,
"Traction", 2015): brainstorm candidate channels broadly, cheap-test each,
then select with rationale. This plugin enforces that the channel-plan field
shows all three stages in order — a chosen channel appearing without a
visible candidate list in the same field is an intra-field ordering
violation, not just a missing-field problem.

## Scope

Only the `channel plan` field, on marketing's own write surfaces:
`docs/issue-<n>/proposals/*marketing*.md` and
`docs/issue-<n>/reports/marketing.md`. The gate only engages when the
proposed content contains a "channel plan" / "channel-plan" section marker;
other writes pass through untouched. This plugin does not vendor or
duplicate the generic record-fields checks from core canon — it sits on top
of them, checking Bullseye-specific structure only.

## Kill switch

`export MARKETING_CHANNEL_GATE_OFF=1` bypasses the gate entirely (fail-open,
intentionally, for emergencies — do not leave it set).

## Testing

Tests for this plugin live in the repo-root `tests/run-gate-tests.sh`, which
is shared across all three marketing plugins and owned by the orchestrator,
not vendored here.

## References

This plugin references core canon for the generic record-field norms and
`docs/issue-1/proposals/rulebook-maturation.md` §b for the channel-plan row
specifically, rather than duplicating that text here.
