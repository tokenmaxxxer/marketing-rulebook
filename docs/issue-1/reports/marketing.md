# Record: issue-1 rulebook maturation (phase 2)

Subject: issue-1

Status: Phase 2 execution, following the issue-level `APPROVE
issue-1/marketing` comment (single-account mode, contract v3 s19). This is
the first phase-2 write to this record file.

## why

Issue #1 asked this rulebook to fix its phase-1/phase-2 methodology norms
into the plugin rather than leaving them as prose in a proposal. The
approved `docs/issue-1/proposals/rulebook-maturation.md` names the exact
edits; this record documents what of that plan was executed now and what
was deliberately deferred.

## what was done

**`marketing/hooks/directive.sh`** — `PRODUCES` line expanded to carry a
methodology pointer per field, exactly as proposal §d sketches:

```
PRODUCES (required record fields):
  messaging doc (positioning canvas — see docs/issue-1/proposals/rulebook-maturation.md §b),
  channel plan (Bullseye 3-phase test — see same),
  target segment (STP + ICP — see same)
```

This directive text is role-unique content inside the `core_role_directive`
heredoc (per issue-2's migration); it is not part of core canon and is not
a copy of shared machinery, so editing it here does not touch the
warrant-hunter/gate-script "reference only, no copy" constraint.

Proposal sections (a) and (c) (phase-1 proposal norms; rationale for the
three methodologies) are directive text, already fully stated in the
approved proposal document itself — the proposal *is* the norm's home;
there is no separate plugin file that restates future phase-1 requirements,
so no further plugin edit corresponds to (a)/(c).

## what was deliberately NOT done, and why

The proposal's §d also sketches a `RECORD_FIELDS_METHODOLOGY` array for
`marketing/hooks/lib/role-config.sh`, giving each required record field a
machine-readable methodology tag. That edit is **not made in this pass**,
per the proposal's own "Sequencing" clause: it requires (1) APPROVE — done
— and (2) issue-2's remaining verification gap to be closed first
(`stub-check.sh` run against real core; `role-config.sh`'s actual
consumption point by core's gate canon confirmed). Checked in this
session: the real `core` repo is still not present in this environment
(no `core/` directory, no `core/hooks/tests/stub-check.sh`), and
`docs/issue-2/reports/implementation.md` still records
`loop_state: blocked-on-external` with that same gap open. Editing
`role-config.sh`'s structure on top of an already-`[ASSUMPTION]`-flagged,
unconfirmed consumption point would compound risk rather than reduce it,
exactly as the proposal warned. This is not a scope cut — it is following
the approved plan's explicit ordering constraint.

## open findings

- `marketing/hooks/lib/role-config.sh`'s `RECORD_FIELDS_METHODOLOGY`
  extension (proposal §d) is not yet made; blocked on issue-2's
  `stub-check.sh` verification gap against real core, which remains open
  (`docs/issue-2/reports/implementation.md`: `loop_state:
  blocked-on-external`). Re-check when a real `core` repo becomes
  available in this environment.
- Proposal's two open questions for the approver (StoryBrand's status;
  the eventual shape of the methodology data structure) remain formally
  open — no further APPROVE-level response was given beyond the
  issue-level `APPROVE issue-1/marketing` comment, so this record does
  not resolve them unilaterally.

## open-finding resolution path

The `role-config.sh` methodology-tag finding resolves once a real `core`
repo is checked out in this (or a follow-up) environment: run
`core/hooks/tests/stub-check.sh` against this rulebook's `directive.sh`/
`hooks.json`, confirm the actual consumption point for role config, then
add `RECORD_FIELDS_METHODOLOGY` to `role-config.sh` matching whatever
shape core's gate canon expects (the proposal's sketch is illustrative,
not binding). Update `docs/issue-2/reports/implementation.md`'s
`loop_state` to a terminal state first, since that record owns the
verification gap; only then revisit this file. The approver open
questions (StoryBrand status; methodology-tag data shape) resolve by the
approver commenting a decision on this issue; no unilateral resolution is
taken here.

## next steps

- Once issue-2's `stub-check.sh` verification lands (real core repo
  available, consumption point confirmed), revisit
  `marketing/hooks/lib/role-config.sh` and add the
  `RECORD_FIELDS_METHODOLOGY` mapping per proposal §d, then close out this
  gap in a follow-up record entry.
- `RECORD_FIELDS_REQUIRED` values in `role-config.sh`
  (`messaging-doc`, `channel-plan`, `target-segment`) already match the
  three fields named in `directive.sh`'s `PRODUCES` line; no rename was
  needed.

## upstream basis

`docs/issue-1/proposals/rulebook-maturation.md` (APPROVEd phase-1
proposal, sections b/c/d) and `docs/issue-2/reports/implementation.md`
(source of the still-open verification-gap fact) are the concrete
upstream basis for every action and deferral above.

## loop_state

loop_state: blocked-on-external

The directive-text edit for this issue is complete; the record-fields
structural edit remains blocked on issue-2's open `stub-check.sh`
verification gap, per the approved proposal's own sequencing constraint.
