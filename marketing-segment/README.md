# marketing-segment

Claude Code plugin implementing the STP + ICP methodology gate (Kotler &
Keller, "Marketing Management"; standard B2B/B2C ICP practice; JTBD as an
optional behavioral lens) for marketing's `target segment` record field.

## Methodology owned

STP (Segmentation, Targeting, Positioning) + ICP (Ideal Customer Profile)
definition. This plugin enforces only the `target segment` field: naming
segmentation criteria, defining a concrete ICP (not a bare demographic
label), and stating targeting rationale against alternative segments. It
does not own positioning, messaging, or channel-mix methodology — those
belong to sibling marketing plugins.

## Scope

`PreToolUse` hook (`hooks/segment-gate.sh`) fires on `Write|Edit|MultiEdit`
targeting:

- `docs/issue-<n>/proposals/*marketing*.md` (phase-1 proposals)
- `docs/issue-<n>/reports/marketing.md` (phase-2 record)

It is silent (exit 0) on any other path — not this gate's business. On an
in-scope path, the resulting content must carry a recognizable
target-segment section (heading, bold label, or bare marker); if none is
found, the write is **denied**, not silently allowed. Once a section is
found, checks are scoped to that section's text span only, not the whole
document, and require segmentation-criteria naming, an ICP definition, and
targeting rationale — denying (exit 2) and listing exactly which
element(s) are missing otherwise. The targeting-rationale check accepts a
labeled reasoning phrase, or a bare `vs` cue only when it sits near a list
item or a named (capitalized) alternative segment.

`Edit`/`MultiEdit` writes are reconstructed against the file's current
content, honoring each edit's own `replace_all` flag; the gate denies
(rather than guessing) when an edit's `old_string` cannot be matched
against the intermediate text.

## Kill switch

`export MARKETING_SEGMENT_GATE_OFF=<1|true|yes|on>` bypasses the gate. Any
other value — unset, empty, `"0"`, or anything unrecognized — leaves the
gate **active**; the gate never fails open on a garbage value.

## Testing

Tests live in the repo-root `tests/run-gate-tests.sh` (shared across all
three marketing plugins), not inside this plugin directory.

## Relationship to core canon

This plugin layers on top of — never replaces — the core canon's generic
record-fields gate. It references core canon conventions (fail-closed
trap, kill-switch pattern, path resolution against `CLAUDE_PROJECT_DIR` /
git root) rather than vendoring or duplicating them.
