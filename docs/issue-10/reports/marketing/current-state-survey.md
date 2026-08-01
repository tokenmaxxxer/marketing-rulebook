# Current-State Survey — issue #10 (gate A+ hardening, marketing)

Status: phase-1 survey. No code changed.

## 1. Precondition check: core issue #72 "gate house standard"

`core/hooks/lib/gate-lib.sh` and `docs/handbooks/gate-house-standard.md` do
**not** exist anywhere in this repo:

```
$ git log main -- core/hooks/lib/gate-lib.sh docs/handbooks/gate-house-standard.md
(empty)
$ find . -path '*/core/hooks/lib/gate-lib.sh'
(empty)
$ find . -iname 'core*' -maxdepth 3
(empty)
```

There is no `core/` directory in this repo at all (checked with `find .
-maxdepth 3 -iname "core*"`, zero hits). `marketing/hooks/directive.sh:9`
already sources `${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/role-directive.sh`
by convention, and prior issue-2 work (`docs/issue-2/reports/implementation/survey.md`,
`docs/issue-2/proposals/core-canon-migration.md`) documents that the real
`core` repo/plugin has consistently been unavailable in this development
environment — this is a known, pre-existing cross-repo dependency, not new
to issue #10.

**Precondition is NOT met.** Per the task instructions: this design is
written to reference `gate-lib.sh`'s *expected* public contract (a shared
fail-closed trap helper, a JSON-payload parser/validator, a path-normalize/
under-root helper, and a kill-switch resolver), and the concrete function
names must be reconfirmed once core issue #72 actually lands. The gate-a-plus
proposal calls this out again at the point of adoption.

## 2. Current hook architecture

The marketing role is a plugin set of four plugins (landed in commit
`9d8f21f`, "Phase-2: implement marketing methodology plugin set (#7)"):

| Plugin | Hook file | Methodology | Kill switch |
|---|---|---|---|
| `marketing` | `marketing/hooks/directive.sh` | orchestration only (SessionStart directive; sources the 3 fragments below) | n/a (no gate, only directive) |
| `marketing-messaging` | `marketing-messaging/hooks/messaging-gate.sh` | Dunford positioning canvas | `MARKETING_MESSAGING_GATE_OFF` |
| `marketing-channel` | `marketing-channel/hooks/channel-gate.sh` | Bullseye 3-phase test (owned/earned/paid) | `MARKETING_CHANNEL_GATE_OFF` |
| `marketing-segment` | `marketing-segment/hooks/segment-gate.sh` | STP + ICP | `MARKETING_SEGMENT_GATE_OFF` |

All three gate scripts are structurally near-identical (same skeleton,
independently duplicated): bash preamble with `trap __fc EXIT` fail-closed
wrapper (lines 1-3 of each), a kill-switch `case` block, a `_target`/`_under`
path-plausibility probe, a project-root resolution block, then a heredoc'd
Python 3 body that does the JSON parse, path-under-root check, section-marker
sniff, and field-completeness check. `marketing/hooks/lib/role-config.sh`
holds required-field names, annotated `[ASSUMPTION] currently unused pending
core's actual gate-canon wiring` — i.e. even the maintainers flag this as
speculative/unconfirmed wiring to a `core` record-fields-gate that does not
exist in this repo.

Wired via each plugin's `hooks/hooks.json` as `PreToolUse` on
`Write|Edit|MultiEdit` (per each script's own header comment, e.g.
`marketing-messaging/hooks/messaging-gate.sh:4`).

## 3. Exact file:line locations of the 3 audited defects

### Defect 1 — self-disabling gate (fail-open on absent marker string)

`marketing-messaging/hooks/messaging-gate.sh:169`

```python
if "messaging doc" not in low and "messaging-doc" not in low:
    sys.exit(0)
```

This runs *after* the write has already been confirmed to target a marketing
proposal/record path (lines 118-123). If the literal substring `"messaging
doc"` / `"messaging-doc"` is absent from the new content, the entire
methodology check is skipped — `exit(0)` = allow. An author can satisfy
every required field elsewhere in the document and simply never use that two
-word marker (or misspell it, or use a heading variant like `## Messaging`)
to permanently disable this gate for that write. This is the "self-defeating
self-disable" described in the issue. The parallel per-methodology markers
have the identical shape and the identical defect:
- `marketing-channel/hooks/channel-gate.sh:165` (`"channel plan"` /
  `"channel-plan"`)
- `marketing-segment/hooks/segment-gate.sh` (`"target segment"` /
  `"target-segment"` marker check, same pattern, a few lines into the same
  heredoc body)

### Defect 2 — owned/earned/paid "any-one-of" matching (effectively unfalsifiable)

`marketing-channel/hooks/channel-gate.sh:200-202`

```python
# d) owned/earned/paid classification
if not has_any("owned", "earned", "paid"):
    missing.append("owned-earned-paid")
```

`has_any` (defined at `channel-gate.sh:168-169`) is `any(nd in low for nd in
needles)` — a single occurrence of any *one* of the three words anywhere in
the document satisfies the whole "owned/earned/paid classification" check.
Because `"paid"` alone appears near-unconditionally in any channel-plan text
that discusses "paid search"/"paid social" (which are themselves two of the
`CHANNEL_KEYWORDS` at line 174), this check is close to unconditionally true
whenever a channel-plan section exists at all — it does not verify that
channels are actually being *classified* into all three buckets, only that
one of the three words appears once.

### Defect 3 — substring-only semantic match (bare "vs." passes)

`marketing-messaging/hooks/messaging-gate.sh:178-181`

```python
# a) competitive-alternatives language
if not has_any(
    "competitive alternative", "competing alternative", "alternative(s) considered",
    "alternatives considered", "compared to", "vs.", "instead of",
):
    missing.append("competitive-alternatives")
```

`"vs."` is one of the accepted needles for `has_any`, which is a raw
substring test (`nd in low`, `channel-gate.sh:168-169` / same helper
duplicated in `messaging-gate.sh:172-173`). Any occurrence of the two
characters `vs.` anywhere in the document — including inside an unrelated
sentence, a citation, a table header, or a typo — satisfies the entire
"competitive-alternatives" requirement. There is no check that the match sits
near a competitor name, inside a dedicated section, or attached to any
structural marker. The same shallow-substring pattern is reused for every
other check in all three gates (`unique-attributes`, `market-category`,
`positioning-statement` in messaging-gate.sh; `test-criteria`,
`chosen-channel` in channel-gate.sh; `targeting-rationale` in
segment-gate.sh), so the defect class is systemic, not a one-off.

## 4. Secondary defect noticed during survey (in scope for the proposal per issue's fail-closed/kill-switch requirement)

`marketing-messaging/hooks/messaging-gate.sh:29-32` (and the identical
pattern in `channel-gate.sh:25-28`, `segment-gate.sh`):

```bash
case "${MARKETING_MESSAGING_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```

The `case` statement's default arm (`*`) — reached by *any* value not in the
explicit off-list, including typos, unexpected truthy strings like `"1"` or
`"TRUE"`, or garbage — resolves to `exit 0`, i.e. **gate disabled**. This is
backwards from the issue's required "unrecognized kill-switch value ⇒ gate
ACTIVE" principle: today, an unrecognized value silently *disables* the
gate rather than defaulting to active. This is flagged here because the
issue's required design explicitly calls out kill-switch fail-closed
behavior as in scope, and it is the same file family as defects 1-3.

## 5. What is already fail-closed (do not regress)

To keep the proposal precise about what changes vs. what stays: all three
gates already have — `trap __fc EXIT` at the top of the bash script
(lines 1-3), malformed-JSON → `deny(...)` in the Python body (e.g.
`messaging-gate.sh:87-88`), `tool_input` not a dict → deny
(`messaging-gate.sh:94-95`), and an `except Exception` wrapper around the
whole Python body that denies on any internal error
(`messaging-gate.sh:210-212`). These are real fail-closed mechanisms already
in place and should be preserved/reused via gate-lib.sh once adopted, not
rebuilt from scratch. The defects are specifically: (a) the post-match
marker-absence bypass (defect 1), (b) the any-of-three logic (defect 2), (c)
substring-only matching (defect 3), and (d) the kill-switch's inverted
default (secondary defect, §4).

## 6. README/code drift noticed (input to the proposal's reconciliation item)

- `marketing/hooks/lib/role-config.sh:2` self-annotates `[ASSUMPTION]
  currently unused pending core's actual gate-canon wiring — core was not
  available in this environment to confirm the real consumption point.` —
  i.e. this config file's actual consumer does not exist yet.
- Root `README.md` states "The record-fields gate, the commit trailer gate,
  and the s21 handbook-sync gate no longer have role-local copies in this
  repo — they are registered role-agnostically in `core/hooks/`" — but
  `core/` does not exist in this repo (§1), so this statement is currently
  unverifiable/misleading as written and should be qualified or reconciled
  in phase-2.
- Each of the three plugin READMEs (`marketing-messaging/README.md`,
  similarly for channel/segment) documents the current (defective)
  behavior — e.g. `marketing-messaging/README.md:25-29` describes the
  five-canvas-element check without noting the marker-gated bypass or the
  substring-matching weakness. These need to be updated in phase-2 to match
  the corrected implementation, not just today's ghost-file cleanup.
</content>
