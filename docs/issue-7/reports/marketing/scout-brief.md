# Scout brief: hook-machine rigor bar for issue #7 (internal field — sibling rulebooks)

Subject: issue-7. Field scouted: this system's own prior art (other
roles' hook/gate machines on this machine), not an external market —
per issue #7's framing, the bar to match is RIGOR, not content.

**Must-bes it assumes** (present in every gate reviewed): fail-closed
trap installed as the *first* executable line, before any `set`/`source`
(non-2 PreToolUse exit = fail-open, so any crash must be forced to
deny); JSON tool-call payload read from stdin and parsed defensively
(`try/except`, deny on unparseable); target path resolved against the
real project root, not assumed cwd; a narrow regex-scoped write surface
so the gate is silent on files outside its own role's business; content
reconstruction for `Write`/`Edit`/`MultiEdit` (deny if the resulting text
can't be determined, rather than guessing); an internal `except
Exception` catch-all that also denies.

**Performance axes observed across the field**: (1) specificity of the
required-element check (keyword/regex list per field, not a generic
"non-empty" check); (2) whether ordering/sequencing is enforced via a
different role's record file (coding<->verify) or is single-role
(pricing has none); (3) test coverage as real subprocess invocations
against a throwaway git repo, not unit tests of internal functions.

**One pattern to adopt**: pricing's `methodology-gate.sh` shape —
narrow regex on `docs/issue-<n>/proposals/*marketing*.md` and
`docs/issue-<n>/reports/marketing.md`, keyword-list checks per required
mandatory-component (per issue #1 §b), fail-closed throughout. This
fits directly: marketing already has three named methodologies with
enumerated mandatory components, exactly pricing's shape.

**One pattern to skip**: coding's cross-role blocking-finding state
machine (`coding-progress-gate.sh` reading `verify.md`). Marketing's
three adopted methodologies (positioning canvas, Bullseye, STP+ICP) have
no adopted inter-field ordering dependency comparable to coding's
build->verify->resolve cycle; importing that machinery would invent a
sequencing constraint issue #1/#5/#6 never asked for. Skip full
cross-role state tracking; if any ordering is warranted it is intra-
record (e.g. Bullseye's brainstorm-before-select), not cross-role.

**Gap line**: marketing already meets the "methodology named" bar
(directive `PRODUCES` pointer, issue #6). It is missing everything else
in the must-bes list above: no `PreToolUse` gate exists, no fail-closed
trap, no keyword-level required-component check, no gate tests, no
`state.sh`.

**Sources** (file paths read):
`/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh`,
`/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/directive.sh`,
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh`,
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/directive.sh`,
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/state.sh`,
`/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh`,
`docs/issue-1/proposals/rulebook-maturation.md` (this repo, mandatory-
component lists §b), `docs/issue-1/reports/marketing.md` (this repo).
