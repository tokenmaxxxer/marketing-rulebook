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

Only marketing's own write surfaces: `docs/issue-<n>/proposals/*marketing*.md`
and `docs/issue-<n>/reports/marketing.md`; other paths pass through
untouched. On an in-scope path, the write's new content must carry a
recognizable channel-plan section (heading, bold label, or bare marker) —
if none is found, the write is **denied**, not silently allowed; an
in-scope write cannot skip the field entirely. Once found, all checks are
scoped to that section's text span only, not the whole document. This
plugin does not vendor or duplicate the generic record-fields checks from
core canon — it sits on top of them, checking Bullseye-specific structure
only.

The owned/earned/paid classification requires **all three** labels
(`owned:`, `earned:`, `paid:` or the parenthesized form) each attached to
a channel inside the section — a document that only mentions one of the
three words in passing (e.g. "paid social" as a candidate-channel name) no
longer satisfies the other two axes.

`Edit`/`MultiEdit` writes are reconstructed against the file's current
content, honoring each edit's own `replace_all` flag; the gate denies
(rather than guessing) when an edit's `old_string` cannot be matched
against the intermediate text.

## Kill switch

`export MARKETING_CHANNEL_GATE_OFF=<1|true|yes|on>` bypasses the gate. Any
other value — unset, empty, `"0"`, or anything unrecognized — leaves the
gate **active**; the gate never fails open on a garbage value.

## Testing

Tests for this plugin live in the repo-root `tests/run-gate-tests.sh`, which
is shared across all three marketing plugins and owned by the orchestrator,
not vendored here.

## References

This plugin references core canon for the generic record-field norms and
`docs/issue-1/proposals/rulebook-maturation.md` §b for the channel-plan row
specifically, rather than duplicating that text here.
