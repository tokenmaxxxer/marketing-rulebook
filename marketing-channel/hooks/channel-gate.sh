#!/usr/bin/env bash
# Sources core's gate-lib.sh (docs/handbooks/gate-house-standard.md) for the
# shared fail-closed trap, kill-switch convention, and Bash-write-target
# detection, instead of hand-rolling them locally.
. "${CLAUDE_PLUGIN_ROOT_CORE:-${CLAUDE_PLUGIN_ROOT}/../core}/hooks/lib/gate-lib.sh" \
  || { echo "channel-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
# PreToolUse gate (Write|Edit|MultiEdit|Bash) — marketing-role-specific, on top of
# (never instead of) the core canon record-fields-gate.sh's generic §20
# fields.
#
# Targets: docs/issue-<n>/proposals/*marketing*.md (phase-1 proposals) and
# docs/issue-<n>/reports/marketing.md (phase-2 record) — this role's own
# write surfaces per docs/issue-1/proposals/rulebook-maturation.md §b
# (channel plan row).
#
# Fires whenever the write targets an in-scope path. If the reconstructed
# new content carries no recognizable channel-plan section (heading, bold
# label, or bare marker), the write is DENIED — an in-scope write that
# omits the field entirely is not exempt (issue #10 defect 1 fix); once a
# section is found, checks are scoped to that section's span only, not the
# whole document (issue #10 defect 3 fix).
#
# Enforces the Bullseye Framework 3-phase test (Weinberg & Mares, "Traction",
# 2015) for the channel-plan field specifically: candidate channels must be
# brainstormed and shown before a channel is selected, each candidate must
# carry test criteria/rationale, the chosen channel must carry its own
# rationale, and the plan must classify EVERY listed channel as owned,
# earned, AND paid (all three labels required, issue #10 defect 2 fix — a
# single "paid" mention no longer satisfies all three axes).
#
# Kill switch: export MARKETING_CHANNEL_GATE_OFF=<1|true|yes|on>
# Any other value (including unset/empty/garbage) leaves the gate ACTIVE.
set -uo pipefail

role="${CLAUDE_ROLE:-marketing}"
deny() { gate_deny "$role" "$1"; }

gate_kill_switch_active "${MARKETING_CHANNEL_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || deny "channel-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "channel-gate: empty tool-use payload on stdin; cannot evaluate the channel-plan gate."

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

# Bash-write coverage (issue #13 defect: matcher/code parity).
_tool_name="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
print(e.get("tool_name","") if isinstance(e,dict) else "")
' 2>/dev/null || true)"

_bash_target=""
if [ "$_tool_name" = "Bash" ]; then
  _cmd="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
v=ti.get("command") if isinstance(ti,dict) else None
print(v) if isinstance(v,str) else None
' 2>/dev/null || true)"
  if [ -n "$_cmd" ]; then
    while IFS= read -r _tok; do
      case "$_tok" in
        *docs/issue-*/proposals/*marketing*.md|*docs/issue-*/reports/marketing.md) _bash_target="$_tok" ;;
      esac
    done <<BASHTOK
$(gate_bash_write_targets "$_cmd")
BASHTOK
  fi
fi
[ -n "$_bash_target" ] && _target="$_bash_target"

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (channel-plan check cannot run)."

CG_PAYLOAD="$payload" CG_ROOT="$root" CG_BASH_TARGET="$_bash_target" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys, importlib.util

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

    def deny(m):
        sys.stderr.write("marketing: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("CG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge channel-plan fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on channel-plan.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (channel-plan).")

    root = posixpath.normpath(os.environ["CG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*marketing.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/marketing\.md$')

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
    elif tool == "Bash":
        p = os.environ.get("CG_BASH_TARGET") or None
        if p:
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
            deny("%s exists but cannot be read; failing closed on channel-plan." % rel)

    new_text = None
    if tool in ("Write", "Edit", "MultiEdit"):
        new_text, _ok = gate_lib.gate_reconstruct_write(tool, ti, current)

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the channel-plan fields can be "
            "checked." % (rel, tool)
        )

    # --- section location, same three-layer approach as messaging-gate.sh
    SECTION_RES = (
        r'(?im)^#{1,6}[ \t]*channel[ \t-]*plan\b.*$',
        r'(?im)^\*\*[ \t]*channel[ \t-]*plan[ \t]*:?\*\*',
        r'(?im)\bchannel[ \t-]plan\b',
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
            "channel-plan section (heading, bold label, or bare marker) was found "
            "in the resulting content; a marketing write surface must carry its "
            "methodology field explicitly, even to say it is deferred." % rel
        )

    low = section.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    CHANNEL_KEYWORDS = (
        "seo", "content marketing", "email", "paid search", "paid social",
        "affiliate", "pr", "events", "community", "referral", "sales",
        "partnerships", "direct sales", "viral", "engineering as marketing",
        "offline",
    )

    def has_candidate_list():
        if "candidates:" in low:
            return True
        found = {kw for kw in CHANNEL_KEYWORDS if kw in low}
        return len(found) >= 2

    missing = []

    # a) candidate-channel list
    candidate_present = has_candidate_list()
    if not candidate_present:
        missing.append("candidate-list")

    # b) test-criteria/rationale language
    if not has_any("test criteria", "test rationale", "cheap test", "criteria:", "rationale:"):
        missing.append("test-criteria")

    # c) chosen-channel-with-rationale marker
    chosen_present = has_any("chosen channel", "selected channel", "we chose", "chosen:")
    if not chosen_present:
        missing.append("chosen-channel")

    # d) owned/earned/paid classification — ALL THREE must each be attached
    # to a label (":"/"-"/parenthesized), not merely mentioned anywhere in
    # the section (issue #10 defect 2 fix).
    def label_found(lbl):
        return bool(re.search(r'\b%s\b\s*[:\-\u2013]' % lbl, low)) or bool(re.search(r'\(%s\)' % lbl, low))

    labels_found = {lbl for lbl in ("owned", "earned", "paid") if label_found(lbl)}
    if labels_found != {"owned", "earned", "paid"}:
        missing_axes = sorted({"owned", "earned", "paid"} - labels_found)
        missing.append("owned-earned-paid (missing: %s)" % ", ".join(missing_axes))

    # e) intra-field ordering check (Bullseye-specific): chosen without candidates
    ordering_violation = chosen_present and not candidate_present
    if ordering_violation and "candidate-list" not in missing:
        missing.append("candidate-list")

    if missing:
        if ordering_violation and set(missing) == {"candidate-list"}:
            named_missing = "candidate-list (Bullseye ordering: chosen channel without candidates shown)"
        else:
            named = []
            for m in missing:
                if m == "candidate-list" and ordering_violation:
                    named.append("candidate-list (Bullseye ordering: chosen channel without candidates shown)")
                else:
                    named.append(m)
            named_missing = ", ".join(named)
        deny(
            "channel plan missing required element(s): %s. Per "
            "docs/issue-1/proposals/rulebook-maturation.md §b (channel plan row), "
            "every channel-plan write must show candidate channels, test "
            "criteria/rationale, a chosen channel with rationale, and owned/earned/paid "
            "classification — and Bullseye's brainstorm-before-select order means a "
            "chosen channel cannot appear without a visible candidate list in the same "
            "field." % named_missing
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("channel-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "marketing: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
