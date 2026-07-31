# marketing-messaging

A self-contained Claude Code plugin that enforces April Dunford's
positioning-canvas methodology ("Obviously Awesome", 2019) on marketing's
`messaging doc` record field.

## Methodology owned

The Dunford positioning canvas: name competitive alternatives, name unique
attributes, translate those into a per-segment value proposition, name the
market category, and synthesize a one-line positioning statement that is
traceable to a named competitive alternative. See
`hooks/directive-fragment.sh` for the exact directive text sourced into the
marketing role's SessionStart directive.

## What it gates

Only the `messaging doc` section of marketing's write surfaces:
`docs/issue-<n>/proposals/*marketing*.md` and
`docs/issue-<n>/reports/marketing.md`. Any other path, or a matching path
whose new content has no `messaging doc` / `messaging-doc` section marker,
passes through untouched — this gate is scoped to the messaging-doc field
only, not the whole record.

When a messaging-doc section is present, the gate (`hooks/messaging-gate.sh`,
wired via `hooks/hooks.json` on `PreToolUse` for `Write|Edit|MultiEdit`)
denies the write unless the new text shows all five canvas elements:
competitive alternatives, unique attributes, a per-segment value
proposition, the market category, and a one-line positioning statement.

## Kill switch

`export MARKETING_MESSAGING_GATE_OFF=1` bypasses the gate entirely.

## Tests

Run `tests/run-gate-tests.sh` from the repo root — it covers all three
marketing methodology plugins, not just this one.

## Notes

This plugin references core canon (the generic record-fields gate and
role-handoff contract) rather than vendoring it; it only adds the
marketing-specific messaging-doc methodology check on top.
