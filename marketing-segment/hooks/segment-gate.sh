#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — marketing-role-specific STP+ICP
# methodology gate for the "target segment" record field, on top of (never
# instead of) the core canon record-fields-gate.sh's generic §20 fields.
#
# Targets: docs/issue-<n>/proposals/*marketing*.md (phase-1 proposals) and
# docs/issue-<n>/reports/marketing.md (phase-2 record) — this role's own
# write surfaces per docs/issue-1/proposals/rulebook-maturation.md §b
# (target segment row).
#
# Fires whenever the write targets an in-scope path. If the reconstructed
# new content carries no recognizable target-segment section (heading,
# bold label, or bare marker), the write is DENIED — an in-scope write
# that omits the field entirely is not exempt (issue #10 defect 1 fix);
# once a section is found, checks are scoped to that section's span only,
# not the whole document (issue #10 defect 3 fix).
#
# Requires that the section name segmentation criteria, define a concrete
# ICP (not a bare demographic label), and state targeting rationale
# against alternative segments. Fails closed when a required element is
# absent, mirroring the reference methodology-gate.sh's fail-closed
# pattern.
#
# Kill switch: export MARKETING_SEGMENT_GATE_OFF=<1|true|yes|on>
# Any other value (including unset/empty/garbage) leaves the gate ACTIVE.
set -uo pipefail

role="${CLAUDE_ROLE:-marketing}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${MARKETING_SEGMENT_GATE_OFF:-}" in
  1|true|yes|on) exit 0 ;;   # explicit, recognized opt-out only
  *) ;;                      # empty, "0", or any unrecognized value -> ACTIVE
esac

command -v python3 >/dev/null 2>&1 || deny "segment-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "segment-gate: empty tool-use payload on stdin; cannot evaluate the methodology gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (methodology check cannot run)."

SG_PAYLOAD="$payload" SG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("marketing: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("SG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge the target segment field on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on the target segment gate.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (target segment).")

    root = posixpath.normpath(os.environ["SG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*marketing.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/marketing\.md$', re.I)

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if r != root and not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not (PROPOSAL_RE.match(rel) or RECORD_RE.match(rel)):
        sys.exit(0)  # not a marketing write surface — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on the target segment gate." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n) if ti.get("replace_all") else current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n) if e.get("replace_all") else text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the target segment field can be "
            "checked." % (rel, tool)
        )

    # --- section location, same three-layer approach as messaging-gate.sh
    SECTION_RES = (
        r'(?im)^#{1,6}[ \t]*target[ \t-]*segment\b.*$',
        r'(?im)^\*\*[ \t]*target[ \t-]*segment[ \t]*:?\*\*',
        r'(?im)\btarget[ \t-]segment\b',
    )

    def find_section(text):
        for pat in SECTION_RES:
            m = re.search(pat, text)
            if m:
                nxt = re.search(r'(?m)^#{1,6}[ \t]', text[m.end():])
                end = m.end() + nxt.start() if nxt else len(text)
                return text[m.start():end]
        return None

    section = find_section(new_text)
    if section is None:
        deny(
            "this write targets %s, a marketing record/proposal path, but no "
            "target-segment section (heading, bold label, or bare marker) was found "
            "in the resulting content; a marketing write surface must carry its "
            "methodology field explicitly, even to say it is deferred." % rel
        )

    low = section.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    def near(cue_pattern, anchor_pattern, window_lines=3):
        lines = section.splitlines()
        cue_lines = [i for i, l in enumerate(lines) if re.search(cue_pattern, l, re.I)]
        for i in cue_lines:
            window = "\n".join(lines[max(0, i - window_lines):i + window_lines + 1])
            if re.search(anchor_pattern, window):
                return True
        return False

    CRITERIA = ("demographic", "firmographic", "behavioral", "psychographic")
    criteria_present = [c for c in CRITERIA if c in low]

    missing = []

    # a) segmentation-criteria naming
    if not criteria_present:
        missing.append("segmentation-criteria-naming")

    # b) ICP-definition marker: explicit "icp:" block OR 2+ distinct
    #    criterion types present (a bare single demographic label fails).
    icp_marker = "icp:" in low
    if not (icp_marker or len(criteria_present) >= 2):
        missing.append("icp-definition")

    # c) targeting-rationale language: a labeled reasoning phrase, or the
    # bare "vs" cue anchored near a named (capitalized) alternative segment
    # or list item — a lone "vs" with nothing beside it no longer counts
    # (issue #10 defect 3 fix, applied to this field's cue too).
    if not has_any("why this segment", "rather than", "over other segment", "over the"):
        cue = r'(^|\s)vs(\.|\s|$)'
        anchor = r'(^\s*[-*]\s)|([A-Z][a-zA-Z0-9]*(\s+[A-Z][a-zA-Z0-9]*)*)'
        if not near(cue, anchor):
            missing.append("targeting-rationale")

    if missing:
        deny(
            "target segment missing required element(s): %s. Per "
            "docs/issue-1/proposals/rulebook-maturation.md §b (target segment row), "
            "every target-segment write must name segmentation criteria, define a "
            "concrete ICP (not a bare demographic label), and state targeting "
            "rationale against alternative segments." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("segment-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "marketing: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
