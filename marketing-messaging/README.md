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

Only marketing's write surfaces: `docs/issue-<n>/proposals/*marketing*.md`
and `docs/issue-<n>/reports/marketing.md`. Any other path passes through
untouched (not this gate's business). On an in-scope path, the gate
(`hooks/messaging-gate.sh`, wired via `hooks/hooks.json` on `PreToolUse`
for `Write|Edit|MultiEdit`) requires the new content to carry a
recognizable messaging-doc section — a markdown heading (`## Messaging
Doc`), a bold label (`**Messaging Doc:**`), or the bare marker
(`messaging doc` / `messaging-doc`) — and **denies** if none is found; an
in-scope write cannot silently skip the field entirely.

Once a section is located, every check is scoped to that section's text
span only (up to the next markdown heading or end of file), not the whole
document — a stray match elsewhere in the file no longer counts. Within
the section, the gate requires all five canvas elements: competitive
alternatives, unique attributes, a per-segment value proposition, the
market category, and a one-line positioning statement. The
competitive-alternatives check specifically accepts either a labeled block
(`Competitive alternatives:` / `Alternatives considered:`) or a cue word
(`vs.`, `compared to`, `instead of`, `alternative(s)`) sitting near a list
item or a named (capitalized) alternative — a bare `vs.` with nothing
named beside it does not satisfy the check.

`Edit`/`MultiEdit` writes are reconstructed against the file's current
content, honoring each edit's own `replace_all` flag; the gate denies
(rather than guessing) when an edit's `old_string` cannot be matched
against the intermediate text.

## Kill switch

`export MARKETING_MESSAGING_GATE_OFF=<1|true|yes|on>` bypasses the gate.
Any other value — unset, empty, `"0"`, or anything unrecognized — leaves
the gate **active**; the gate never fails open on a garbage value.

## Tests

Run `tests/run-gate-tests.sh` from the repo root — it covers all three
marketing methodology plugins, not just this one.

## Notes

This plugin references core canon (the generic record-fields gate and
role-handoff contract) rather than vendoring it; it only adds the
marketing-specific messaging-doc methodology check on top.
