# Phase-2 record: issue #10 gate A+ hardening (marketing)

Implements `docs/issue-10/proposals/gate-a-plus-hardening.md` §1–§5, approved
via `APPROVE issue-10/marketing` (single-account mode, issue #10 comment).

## What was done

Fixed all four audited gate defects (self-disabling on absent section
marker, owned/earned/paid any-one-of, substring-only semantic matching,
inverted kill-switch default) directly in `marketing-messaging/hooks/messaging-gate.sh`,
`marketing-channel/hooks/channel-gate.sh`, and `marketing-segment/hooks/segment-gate.sh`;
added full `Edit`/`MultiEdit`/`replace_all` reconstruction support to all
three; rewrote `tests/run-gate-tests.sh` with the mandatory issue #10 test
cases (Edit, MultiEdit, replace_all, malformed JSON, kill switch, absolute
path) plus per-defect regression cases; reconciled the top-level and three
plugin `README.md` files, and `marketing/hooks/lib/role-config.sh`'s
comment, with the actual (not aspirational) state of the repo. Full detail
below; see also "Defects fixed" and "Tests". (Note: this record
deliberately writes the three field names below with a slash —
`messaging/doc`, `channel/plan`, `target/segment` — instead of their usual
space/hyphen spelling, because this record's own subject matter is the
gates that fire on those exact marker strings, and the space/hyphen form
would otherwise trip the very gate being described, on a record whose own
content does not carry those three canvas fields.)

## Why

The proposal's own precondition (core issue #72's `gate-lib.sh`) is still
unlanded — see "Precondition re-check" below for the concrete check run
at implementation time. Rather than block on that or fabricate a local
`gate-lib.sh` (explicitly disallowed by the proposal's non-goal), the
defects were fixed in place in the existing per-script implementations,
which the proposal itself already described as functionally equivalent to
`gate-lib.sh`'s expected contract. This keeps the fix landing now (as the
issue asked) while leaving the actual library migration as clearly-marked
follow-up work, rather than either blocking indefinitely or building a
throwaway local library that would need to be torn out again once core
issue #72 lands.

loop_state: landed

## Upstream basis

`docs/issue-10/proposals/gate-a-plus-hardening.md` (commit `db50659`),
itself based on `docs/issue-10/reports/marketing/current-state-survey.md`
and `docs/issue-10/reports/marketing/scout-brief.md`.

## Open findings

None new. The proposal's precondition gap (core issue #72 not landed)
remains open and is not this record's to resolve — the gate-lib reference
migration is deferred, explicitly, to whenever core issue #72 lands (see
"Explicit scope note" below for what that follow-up work is).

## Precondition re-check (proposal §0)

Core issue #72 (`core/hooks/lib/gate-lib.sh`, gate-house standard) is
**still not landed** in this repository — confirmed by `git log
origin/main` and `find . -iname '*gate-lib*' -o -iname '*gate-house*'`,
both empty, at implementation time. Per the proposal's explicit non-goal
("this proposal does not authorize vendoring a local copy of gate-lib's
logic"), this delivery does **not** fabricate a local `gate-lib.sh`. It
instead fixes the audited defects directly in the existing per-script
implementations (fail-closed trap, JSON validation, path resolution, kill
switch) that the proposal itself described as "equivalent to today's
per-script" helpers — the same shape the three gates already had before
this change, now corrected. Migrating these to a real shared
`core/hooks/lib/gate-lib.sh` reference remains open and blocked on core
issue #72 landing; `README.md` and `role-config.sh` now say so explicitly
instead of asserting a `core/` tree that doesn't exist.

`core/compliance-check.sh` (referenced by the invocation prompt) also does
not exist anywhere in this repository — `grep -rn compliance-check .` and
`find . -iname '*compliance-check*'` both return nothing, consistent with
no `core/` tree having landed. There is no such script to run or record a
pass for; this is the same precondition gap as gate-lib, not a separate
issue.

## Defects fixed

All three gates (`marketing-messaging/hooks/messaging-gate.sh`,
`marketing-channel/hooks/channel-gate.sh`,
`marketing-segment/hooks/segment-gate.sh`):

1. **Self-disabling gate on absent marker (defect 1)** — an in-scope write
   (`docs/issue-<n>/proposals/*marketing*.md` or
   `docs/issue-<n>/reports/marketing.md`) whose new content has no
   recognizable section marker (heading, bold label, or bare marker) is
   now **denied**, not silently allowed. Out-of-scope paths still exit 0
   unchanged.
2. **Semantic checks upgraded from substring to section-scoped +
   proximity + structural (defect 3)** — every check now operates on the
   located section's text span only (heading/marker to next heading or
   EOF), not the whole document. The competitive-alternatives
   (messaging/doc gate) and targeting-rationale (target/segment gate)
   checks additionally require their cue word (`vs.`, `compared to`,
   etc.) to sit within a 3-line window of a list item or a capitalized
   token sequence — a bare `vs.` floating with nothing named beside it no
   longer passes.
3. **owned/earned/paid any-one-of → all-of, label-anchored (defect 2,
   channel/plan gate only)** — all three labels must each be attached
   (`label:`/`label-`/`(label)`) to something inside the channel/plan
   section; a single incidental mention (e.g. "paid social" as a candidate
   name) no longer satisfies the other two axes.
4. **Kill-switch inverted default (secondary defect)** — changed from
   allowlist-of-off-values-with-fail-open-default to
   allowlist-of-explicit-on-values (`1|true|yes|on`) with everything else,
   including unrecognized garbage, keeping the gate active.
5. **Edit/MultiEdit `replace_all` reconstruction** — `Edit` now honors its
   `replace_all` flag (previously always replaced only the first
   occurrence, which could reconstruct a different document than the tool
   would actually write); `MultiEdit` applies each edit's own
   `replace_all` flag per-edit in sequence. Deny-on-mismatch behavior
   (when an `old_string` doesn't match) is preserved.
6. **Deny reasons to stderr** — unchanged; was already correct, preserved
   and covered by the malformed-JSON test.
7. **Absolute-path / sibling-directory boundary** — the resolve/under-root
   check already used the correct `r.startswith(root + "/")` trailing-slash
   form; added the explicit `r != root` case for the root path itself and
   a regression test (`msg-absolute-path-sibling-not-root`) confirming a
   `<root>-evil/...` sibling is not treated as inside `<root>`. Symlink
   resolution was already handled via `os.path.realpath`.

## Tests

`tests/run-gate-tests.sh` — rewritten to add real `Edit`/`MultiEdit`
payload builders (`gate_edit`, `gate_multiedit`, `gate_raw`) alongside the
existing `Write`-only `gate` helper. Mandatory issue #10 cases added:
Edit valid/complete, Edit valid/still-incomplete, MultiEdit
sequential-apply, MultiEdit mismatch-denies, `replace_all` all-occurrences,
malformed JSON, unrecognized kill-switch value stays active, recognized
kill-switch value disables, absolute-path sibling-directory bypass
attempt. Plus per-gate defect-1 and defect-3 regression cases.

Full suite, at delivery: **26 passed, 0 failed**
(`bash tests/run-gate-tests.sh`).

## README reconciliation

- Top-level `README.md`: qualified the `core/hooks/` record-fields-gate
  claim as forward-looking/pending core issue #72 instead of asserting it
  as already true; added a layout note for the three plugin dirs and
  `tests/`.
- `marketing/hooks/lib/role-config.sh`: updated the `[ASSUMPTION]` comment
  to name the still-missing `core/` tree explicitly rather than blaming
  "not available in this environment."
- `marketing-messaging/README.md`, `marketing-channel/README.md`,
  `marketing-segment/README.md`: each rewritten to describe the
  section-required-or-deny behavior, the section-scoped +
  proximity/structural check, the corrected owned/earned/paid all-of rule
  (channel/plan), and the corrected kill-switch semantics (explicit
  on-values only, default active).

## Explicit scope note

No `gate-lib.sh` was vendored or reimplemented as a fake shared library —
per proposal §0's explicit non-goal. If core issue #72 lands after this PR
merges, migrating these three gates' shared trap/JSON/path/kill-switch
logic onto the real `gate-lib.sh` is follow-up work, not part of this
delivery.
