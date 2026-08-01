# Proposal: marketing gate A+ hardening (issue #10)

Status: **Phase 1 proposal only — no implementation in this PR.** Phase 2
requires an `approvers.md` APPROVE.

Reference survey: `docs/issue-10/reports/marketing/current-state-survey.md`.
Reference scout: `docs/issue-10/reports/marketing/scout-brief.md`.

## 0. Precondition status

Core issue #72 (gate house standard: `core/hooks/lib/gate-lib.sh`,
`docs/handbooks/gate-house-standard.md`) is **not landed** in this repo —
confirmed absent by `git log` and `find` (survey §1). This design therefore
references `gate-lib.sh`'s *expected* contract only, by role, not by
confirmed function name:

- a fail-closed trap installer (equivalent to today's per-script
  `trap __fc EXIT`),
- a JSON-payload parse/validate helper (malformed JSON → deny),
- an absolute-path normalize/realpath/under-root helper (equivalent to
  today's per-script `_under`/`resolve`), and
- a kill-switch resolver that treats unrecognized values as "active."

**At phase-2 implementation time, whoever picks this up must first re-read
the landed `gate-lib.sh` source and `gate-house-standard.md`, and update the
exact function names/call signatures used below before writing code.** If
issue #72 is still not landed when phase 2 starts, the phase-2 implementer
must escalate rather than reimplementing the library locally (explicit
non-goal: this proposal does not authorize vendoring a local copy of
gate-lib's logic).

## 1. Fix design for the 3 audited defects (+ 1 secondary)

### 1.1 Defect 1 — self-disabling gate on absent marker string

Current: `messaging-gate.sh:169` (`channel-gate.sh:165`, and segment-gate's
equivalent) skip the entire check with `sys.exit(0)` when the literal marker
string is absent from the new content.

Fix: distinguish "this write is not in the marketing methodology's write
surface" (still `exit(0)`, unchanged — a path outside
`docs/issue-<n>/proposals/*marketing*.md` / `reports/marketing.md` is
legitimately out of scope) from "this write is in scope but the required
section is missing or unlabeled." The latter must **deny**, not pass:

```
if not in_write_surface(rel):
    exit(0)                      # unchanged: not this gate's business
section = find_section(new_text, SECTION_HEADINGS)   # see 1.3
if section is None:
    deny("write targets a marketing record/proposal path but no "
         "<field> section (heading or marker) was found; a marketing "
         "write surface must carry its methodology field explicitly, "
         "even to say it is deferred.")
```

`find_section` must accept a small set of recognized heading forms (e.g.
Markdown heading `## Messaging Doc`, bold-line `**Messaging Doc:**`, or the
existing bare marker), not only the single hardcoded phrase — this also
prevents the "misspell the marker to bypass" version of the same bug.

### 1.2 Defect 2 — owned/earned/paid "any-one-of"

Current: `channel-gate.sh:200-202`, `has_any("owned","earned","paid")`.

Fix: change to an **all-of, structurally-anchored** check: all three
classification labels must each be attached to at least one *listed
channel* inside the channel-plan section (not merely present anywhere in
the document). Concretely, within the section body located per §1.3:

```
labels_found = {lbl for lbl in ("owned", "earned", "paid")
                 if re.search(rf'\b{lbl}\b\s*[:\-–]', section_text)
                 or re.search(rf'\(({lbl})\)', section_text)}
if labels_found != {"owned", "earned", "paid"}:
    missing_axes = {"owned", "earned", "paid"} - labels_found
    missing.append(f"owned-earned-paid (missing: {', '.join(sorted(missing_axes))})")
```

This requires each of the three axis words to appear as a *label* (followed
by a colon/dash, or parenthesized) rather than as incidental prose (e.g.
"paid social" in a channel-name list no longer silently satisfies "paid" as
a classification label). Combined with the section-scoping in §1.3, a
document can no longer satisfy this by mentioning "paid" once anywhere in
an unrelated paragraph.

### 1.3 Defect 3 — substring-only semantic matching ("vs." passes)

Current: `has_any(*needles)` = `any(nd in low for nd in needles)` over the
*entire* document text, reused for every check in all three gates.

Fix — three-layer algorithm, replacing the flat substring scan:

1. **Section existence**: locate the relevant section's text span using a
   heading/marker regex (not `in low`), e.g.
   `re.search(r'(?im)^#{1,4}\s*messaging\s*doc\b.*$', text)` OR the existing
   bare-marker fallback from §1.1. Scope all subsequent checks to the text
   between this heading and the next heading of equal-or-higher level (or
   EOF). This alone fixes "vs." appearing in an unrelated part of the
   document — it can no longer count if it's outside the section span.
2. **Proximity**: for checks that require a concept anchored to a specific
   referent (e.g. "competitive alternatives" must name an actual
   alternative, not just contain the word "vs."), require the matched cue
   token and a capitalized-noun-phrase or list-item token within an N-line
   (default N=3) or N-token (default N=25) window of each other, e.g.:
   ```
   def near(cue_pattern, anchor_pattern, text, window_lines=3):
       lines = text.splitlines()
       cue_lines = [i for i,l in enumerate(lines) if re.search(cue_pattern, l, re.I)]
       return any(
           re.search(anchor_pattern, "\n".join(lines[max(0,i-window_lines):i+window_lines+1]))
           for i in cue_lines
       )
   ```
   For "competitive-alternatives": cue = `r'\b(vs\.|compared to|instead of|alternative)\b'`,
   anchor = a list-item marker (`^\s*[-*]\s`) or a capitalized token
   sequence (crude proper-noun heuristic) within the window — i.e. "vs."
   must sit next to something that looks like a named alternative, not
   stand alone.
3. **Structural matching**: prefer an explicit sub-structure where the
   document format allows it — e.g. a `Competitive alternatives:` labeled
   list, an `ICP:` block (already used in segment-gate for defect
   avoidance — segment-gate's `icp_marker = "icp:" in low"` is the one
   already-decent example in the current code and should be the template
   to generalize, not a one-off). When a labeled block is present, skip the
   proximity heuristic and just check the block is non-empty; the
   proximity heuristic is the fallback for prose-only writing, not the
   primary mechanism.

This same three-layer approach replaces every `has_any(...)` call site in
all three gates (survey §3 notes the defect class is systemic, not
localized to one line), each retuned per field:
`unique-attributes`, `market-category`, `positioning-statement`
(messaging-gate), `test-criteria`, `chosen-channel` (channel-gate),
`targeting-rationale` (segment-gate).

### 1.4 Secondary defect — kill-switch inverted default

Current (all three gates): `case "${..._GATE_OFF:-}" in ""|0|false|no|off)
;; *) exit 0 ;; esac` — any unrecognized value disables the gate.

Fix: invert the arms so only an explicit, recognized "on" value disables
the gate; everything else (including unrecognized garbage) keeps the gate
active:

```bash
case "${MARKETING_MESSAGING_GATE_OFF:-}" in
  1|true|yes|on) exit 0 ;;   # explicit, recognized opt-out only
  *) ;;                      # empty, "0", or ANY unrecognized value -> ACTIVE
esac
```

This is the direct implementation of the issue's "unrecognized kill-switch
value = treat gate as ACTIVE" requirement (also matches the scout brief's
default-deny principle, §Must-bes).

## 2. Fail-closed design (trap-at-top, malformed JSON, full tool coverage)

Trap-at-top pseudocode (formalizing what already exists per-script, to be
replaced by `gate-lib.sh`'s shared trap installer once available):

```bash
#!/usr/bin/env bash
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/gate-lib.sh"   # expected, see §0
gatelib_install_fail_closed_trap   # replaces local __fc/trap boilerplate
gatelib_resolve_kill_switch "MARKETING_MESSAGING_GATE_OFF" && exit 0   # §1.4 semantics inside
payload="$(cat)"
gatelib_require_valid_json "$payload" || gatelib_deny "malformed JSON payload"
...
```

Malformed-JSON handling: unchanged in spirit from today's
`json.loads` → `except ValueError: deny(...)` (already correct, survey §5)
— must be preserved verbatim as a behavior when moved into/onto
`gate-lib.sh`, and covered by a regression test (§4) so a refactor cannot
silently regress it.

Unrecognized kill-switch value: per §1.4, resolves to ACTIVE — the shared
`gatelib_resolve_kill_switch` (or equivalent) must implement the inverted
allowlist-of-off-values semantics, not an allowlist-of-on-values with a
denylist default, since the whole point is "we don't guess, we deny/enforce
by default."

Full Edit/MultiEdit/replace_all coverage: the reconstruction logic already
branches on `tool_name` for `Write`/`Edit`/`MultiEdit`
(`messaging-gate.sh:134-155`) but has never been exercised for `MultiEdit`
or for `Edit`'s `replace_all` flag by an automated test (survey — no
existing test references these; confirmed by reading
`tests/run-gate-tests.sh`'s current 12 cases, which are per-gate
happy/deny pairs, not tool-shape variations). The design requirement is:

- `Edit` with `replace_all: true` must be reconstructed by replacing **all**
  occurrences of `old_string`, not just the first (`current.replace(o, n,
  1)` today ignores `replace_all` entirely — this is a correctness gap:
  it could produce a *different* reconstructed document than what the tool
  will actually write, e.g. under-counting occurrences means the gate
  might validate against stale/wrong text). Fix:
  ```python
  count = -1 if ti.get("replace_all") else 1
  new_text = current.replace(o, n, count)
  ```
- `MultiEdit` must apply each edit's own `replace_all` flag the same way,
  per-edit, inside the existing edit-list loop.
- Both must still deny (not silently pass) when `old_string` does not match
  the current content (already correct: `ok = False` path already denies
  via the "gate cannot determine resulting content" message at
  `messaging-gate.sh:157-163` — preserve this, add a test for it, survey §4
  test table).

## 3. Deny reasons to stderr

Already correct in all three gates today (`deny()` writes to `sys.stderr`
in the Python body, and the bash-level `deny()` helper also writes to
stderr) — this is a **preserve**, not a **change**. `gate-lib.sh` adoption
must not regress this; the shared `gatelib_deny` helper's contract must be
confirmed (once landed) to write to stderr and exit 2, matching today's
behavior.

## 4. Mandatory test cases

All of the following must be added to `tests/run-gate-tests.sh` (or its
gate-lib-integrated successor) and the **full suite must be green at
implementation time** before the phase-2 PR can merge.

| Case | Input | Expected result |
|---|---|---|
| Edit — valid, old_string matches | `tool_name=Edit`, in-scope path, `old_string` present in current content, reconstructed text satisfies all required fields | allow (exit 0) |
| Edit — valid, old_string matches, fields still incomplete | same as above but reconstructed text missing e.g. owned/earned/paid all three axes | deny (exit 2), reason names the missing axis on stderr |
| MultiEdit — all edits apply in sequence | `tool_name=MultiEdit`, ordered edit list, each `old_string` present after prior edits applied, final text complete | allow |
| MultiEdit — one edit's old_string does not match | as above but edit #2's `old_string` absent from intermediate text | deny, reason states the gate cannot determine resulting content |
| replace_all=true replaces every occurrence | `Edit` with `replace_all: true`, `old_string` occurs 3x in current content | reconstruction replaces all 3 occurrences (verify via a fixture where only-first-occurrence-replaced would wrongly pass or wrongly fail the field check) |
| Malformed JSON input | payload is not valid JSON (`{"tool_name":`) | deny, "not valid JSON" reason on stderr, exit 2 |
| Unrecognized kill-switch value | `MARKETING_MESSAGING_GATE_OFF=banana` | gate remains ACTIVE (does not exit 0 early); a non-compliant write under this env value is still denied |
| Recognized kill-switch on-value | `MARKETING_MESSAGING_GATE_OFF=1` | gate exits 0 immediately (disabled), confirming intentional opt-out still works |
| Absolute-path bypass attempt | `file_path` given as an absolute path pointing outside project root but crafted to `startswith(root)` via a sibling-directory name collision (e.g. `root + "-evil/docs/issue-1/proposals/marketing.md"`) | denied/ignored correctly — i.e. `r.startswith(root + "/")` (not bare `root`) must reject `root-evil/...`; add a fixture asserting the trailing-slash boundary check specifically |
| Absolute-path bypass via symlink | `file_path` is a symlink inside the project root pointing to a file outside the root | resolved via realpath before the under-root check; must be denied/treated as out-of-scope, not validated against the symlink target's real (external) content |
| Section-marker absent on in-scope path (defect 1 regression test) | in-scope path, new content has no messaging-doc/channel-plan/target-segment section at all | deny (not silent allow) — this is the direct regression test for defect 1 |
| Substring-only match no longer sufficient (defect 3 regression test) | new content contains the bare token `vs.` far from any list/alternative-naming content, with no other qualifying language | deny — this is the direct regression test for defect 3 |
| Owned/earned/paid all-of (defect 2 regression test) | channel-plan section mentions "paid social" as a candidate channel but never labels any channel `owned:`/`earned:`/`paid:` | deny, missing axes named — this is the direct regression test for defect 2 |

## 5. README reconciliation (phase-2 item list)

1. Update `README.md`'s "record-fields gate ... registered role-agnostically
   in `core/hooks/`" claim to either (a) qualify it as forward-looking/
   pending core issue #72, or (b) remove it if it no longer reflects any
   real near-term plan — do not leave an assertion about a `core/`
   directory that does not exist in this repo unqualified.
2. Update `marketing/hooks/lib/role-config.sh`'s `[ASSUMPTION] currently
   unused pending core's actual gate-canon wiring` comment once the actual
   consumption point is confirmed (or delete the file if record-fields
   enforcement is fully superseded by the per-methodology plugin gates).
3. Update each of `marketing-messaging/README.md`,
   `marketing-channel/README.md`, `marketing-segment/README.md` to describe
   the corrected section-existence + proximity + structural check (§1.3),
   replacing the current descriptions that imply flat keyword/substring
   presence is sufficient.
4. Document the corrected kill-switch semantics (§1.4: unrecognized value =
   active) explicitly in each plugin README's "Kill switch" section,
   replacing the current one-line `export ..._GATE_OFF=1` note with the
   full allow-list-of-on-values statement.
5. Remove/update any reference to files or paths that phase-2
   implementation determines no longer exist once gate-lib.sh adoption
   lands (to be finalized against the actual `core/hooks/lib/gate-lib.sh`
   file tree once issue #72 lands — cannot be fully enumerated today per
   §0).

## 6. Explicit phase gate

**Phase 1 proposal only — no implementation in this PR.** No hook, plugin,
test, or README file has been created or modified as part of this
deliverable; only `docs/issue-10/reports/marketing/` and
`docs/issue-10/proposals/` were written. **Phase 2 requires an
`approvers.md` APPROVE** before any of the fixes in §1-§5 are implemented,
and phase-2 implementation must first reconfirm `gate-lib.sh`'s actual
contract per §0 before writing code against it.
</content>
