# Scout Brief — issue #10 (gate A+ hardening, marketing)

4 WebSearch queries run (not blocked): (1) fail-closed/fail-secure gate
design, (2) kill-switch fail-safe default-deny, (3) semantic/structural vs
substring document validation, (4) Claude Code PreToolUse Edit/MultiEdit
matcher normalization.

## Must-bes adopted

- **Default-deny / fail-safe defaults** (Saltzer & Schroeder, 1975, via the
  arc42 quality-model summary and DevSecOps School): treat all unrecognized
  or missing inputs as invalid by default. Directly informs the kill-switch
  fix: an unrecognized `*_GATE_OFF` value must resolve to "gate active," not
  "gate disabled" — inverting today's `case ... *) exit 0` default arm
  (survey §4).
- **Fail-secure vs fail-safe distinction** (basila.medium.com, allegion.ca,
  axis newsroom): fail-secure prioritizes asset/data protection by defaulting
  to denial under failure; fail-safe prioritizes life-safety by defaulting
  to the open state. A CI/write gate is an asset-protection control, not a
  life-safety control, so it should follow **fail-secure** semantics
  throughout: malformed input, internal error, or ambiguous state all deny.
  This matches the "trap-at-top" requirement in the issue and the existing
  `trap __fc EXIT` mechanism already present in the codebase (survey §5) —
  the fix is closing the specific bypass paths, not inventing fail-closed
  from scratch.
- **Structural/proximity matching over substring matching** (arxiv
  2603.18652 "Beyond String Matching"; general IR literature on proximity
  operators and structural cues for section identification): validation
  should identify document *sections* by structural/formatting markers
  first, then check for concept presence *within* that section, optionally
  with a proximity window between co-required terms — not a `nd in
  full_text.lower()` scan over the whole document. Adopted directly into the
  proposal's replacement algorithm for defects 1 and 3.
- **Claude Code hook matcher convention** (claudebuddy.art,
  claudefa.st docs): the standard, already-idiomatic matcher pattern for
  file-mutation tools is `"Edit|Write|MultiEdit"` on `PreToolUse`, with
  `tool_name` in the JSON payload used to branch reconstruction logic per
  tool. The current marketing gates already use this matcher (per each gate
  header) and already branch on `tool_name` for Write/Edit/MultiEdit
  (survey §2) — confirms the existing tool-dispatch shape is the right one
  to keep; the proposal only needs to ensure `replace_all` (an `Edit`
  tool-input flag, not a separate `tool_name`) is explicitly exercised in
  reconstruction and tests, since it changes Edit's replace-count semantics.

## Patterns considered and skipped

- **Full NLP/embedding-based semantic similarity** for the section checks:
  skipped as disproportionate — the issue asks for "section-existence +
  proximity + structural matching," not similarity scoring, and a bash/
  python-only hook should not take on an ML dependency. A regex/heading-
  based section splitter plus proximity-windowed keyword checks satisfies
  the requirement without new runtime dependencies.
- **Physical fail-safe (default-open) framing**: explicitly rejected for
  this use case per the fail-secure/fail-safe distinction above — a write
  gate protecting document quality is not a safety-of-life system, so
  "unlock on failure" is the wrong default.

## Sources

- [Fail-safe versus fail-secure](https://basila.medium.com/fail-safe-versus-fail-secure-584201a7bada)
- [Fail-safe vs fail-secure: What's the difference, & how to choose](https://newsroom.axis.com/en-us/blog/fail-safe-vs-fail-secure)
- [Fail Secure vs. Fail Safe: Decoding Door Security Systems](https://allegion.ca/en/resources/education/leading-the-industry/decoded/fail-safe-vs-fail-secure.html)
- [Fail-Safe Defaults | arc42 Quality Model](https://quality.arc42.org/approaches/fail-safe-defaults)
- [What is Fail-Safe Defaults? — DevSecOps School](https://devsecopsschool.com/blog/fail-safe-defaults/)
- [Kill switches best practices — Unleash](https://medium.com/unleash/kill-switches-best-practices-73be89b9a718)
- [Beyond String Matching: Semantic Evaluation of PDF Table Extraction](https://arxiv.org/html/2603.18652)
- [Semantic matching — Wikipedia](https://en.wikipedia.org/wiki/Semantic_matching)
- [Claude Code Hooks Guide — PreToolUse, PostToolUse & More](https://www.claudebuddy.art/blog/claude-code-hooks-complete-guide)
- [Claude Code Hooks: Complete Guide to All 30 Lifecycle Events](https://claudefa.st/blog/tools/hooks/hooks-guide)
</content>
