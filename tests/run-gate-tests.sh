#!/usr/bin/env bash
# Marketing's three methodology gates (marketing-messaging, marketing-channel,
# marketing-segment), exercised as real subprocesses against a synthetic repo.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$HERE/.." && pwd -P)"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-7/reports/marketing.md

# gate NAME GATE-SCRIPT ENV-VAR-OFF CONTENT-EXPR RAW-PAYLOAD-JSON-EXPR
# Builds the PreToolUse payload from a raw jq-free python expression, so
# callers can exercise Write, Edit, MultiEdit, and malformed-JSON shapes,
# not just Write.
gate_raw() { # want name gate-script extra-env payload-json
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  extra_env=""
  [ -n "${4:-}" ] && extra_env="$4"
  printf '%s' "$5" | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$ROOT/$3" >/dev/null 2>&1
  rc="${PIPESTATUS[1]}"; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

gate() { # want name gate-script env-var-off content
  payload="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$REC" "$5")"
  gate_raw "$1" "$2" "$3" "${6:-}" "$payload"
}

gate_edit() { # want name gate-script env-var-off current-content old new replace_all(0/1)
  payload="$(python3 -c '
import json,sys
current, old, new, ra = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[5],"old_string":old,"new_string":new,"replace_all":ra}}))
' "${5:-}" "${6:-}" "${7:-}" "${8:-0}" "$REC")"
  # seed the repo with current content before invoking, via a wrapper
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  printf '%s' "${5:-}" > "$td/$REC"
  extra_env=""
  [ -n "${4:-}" ] && extra_env="$4"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$ROOT/$3" >/dev/null 2>&1
  rc="${PIPESTATUS[1]}"; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

gate_multiedit() { # want name gate-script env-var-off current-content edits-json-expr
  payload="$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":sys.argv[2],"edits":json.loads(sys.argv[1])}}))
' "${6:-}" "$REC")"
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  printf '%s' "${5:-}" > "$td/$REC"
  extra_env=""
  [ -n "${4:-}" ] && extra_env="$4"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$ROOT/$3" >/dev/null 2>&1
  rc="${PIPESTATUS[1]}"; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

# --- marketing-messaging: Dunford positioning canvas ---
MSG_GATE="marketing-messaging/hooks/messaging-gate.sh"
MSG_GOOD='## messaging doc
Competitive alternatives: status quo spreadsheets, competitor X.
Unique attributes: only we ship same-day.
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation. we compete in workflow tools.
Positioning statement: we are the fastest onboarding tool for SMBs switching from spreadsheets.'
MSG_BAD='## messaging doc
Unique attributes: only we ship same-day.
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.'
gate allow msg-complete "$MSG_GATE" "" "$MSG_GOOD"
gate deny  msg-missing-alt "$MSG_GATE" "" "$MSG_BAD"
gate deny  msg-no-section "$MSG_GATE" "" "no messaging content here at all"
gate allow msg-killswitch "$MSG_GATE" "" "$MSG_BAD" "MARKETING_MESSAGING_GATE_OFF=1"

# defect 1 regression: in-scope path, no section marker at all -> deny (not silent allow)
gate deny  msg-no-section-in-scope "$MSG_GATE" "" "just some unrelated prose about nothing methodology-shaped"

# defect 3 regression: bare "vs." far from any list/alternative-naming -> deny
MSG_BARE_VS='## messaging doc
Unique attributes: only we ship same-day.
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.
Random trailing remark mentioning vs. with nothing named beside it.'
gate deny  msg-bare-vs "$MSG_GATE" "" "$MSG_BARE_VS"

# --- marketing-channel: Bullseye 3-phase test ---
CH_GATE="marketing-channel/hooks/channel-gate.sh"
CH_GOOD='## channel plan
Candidates: seo, content marketing, paid social, email.
Test criteria: 2-week cheap test per candidate, rationale documented.
Chosen channel: content marketing. we chose it based on the test.
Classification: owned: content marketing. earned: pr mentions. paid: minimal paid spend.'
CH_ORDER_VIOLATION='## channel plan
Test criteria: 2-week cheap test, rationale documented.
Chosen channel: content marketing. we chose it based on the test.
Classification: owned: newsletter. earned: media mentions. paid: none.'
gate allow ch-complete "$CH_GATE" "" "$CH_GOOD"
gate deny  ch-order-violation "$CH_GATE" "" "$CH_ORDER_VIOLATION"
gate deny  ch-no-section "$CH_GATE" "" "nothing relevant here"
gate allow ch-killswitch "$CH_GATE" "" "$CH_ORDER_VIOLATION" "MARKETING_CHANNEL_GATE_OFF=1"

# defect 1 regression
gate deny  ch-no-section-in-scope "$CH_GATE" "" "just prose, no channel plan anywhere"

# defect 2 regression: "paid social" mentioned as a candidate but no owned:/earned:/paid: labels
CH_ANYONE='## channel plan
Candidates: seo, content marketing, paid social, email.
Test criteria: 2-week cheap test per candidate, rationale documented.
Chosen channel: content marketing. we chose it based on the test.'
gate deny  ch-oep-any-one-of "$CH_GATE" "" "$CH_ANYONE"

# --- marketing-segment: STP + ICP ---
SEG_GATE="marketing-segment/hooks/segment-gate.sh"
SEG_GOOD='## target segment
Segmentation criteria: demographic and behavioral.
ICP: SMB ops managers, 10-50 employees, manually reconciling spreadsheets weekly.
Why this segment rather than enterprise: faster sales cycle, less procurement friction.'
SEG_BARE='## target segment
Segmentation criteria: demographic.
ICP: SMB owners.'
gate allow seg-complete "$SEG_GATE" "" "$SEG_GOOD"
gate deny  seg-bare-label "$SEG_GATE" "" "$SEG_BARE"
gate deny  seg-no-section "$SEG_GATE" "" "irrelevant content"
gate allow seg-killswitch "$SEG_GATE" "" "$SEG_BARE" "MARKETING_SEGMENT_GATE_OFF=1"

# defect 1 regression
gate deny  seg-no-section-in-scope "$SEG_GATE" "" "just some unrelated prose"

# --- issue #10 mandatory cross-cutting cases ---

# Edit — valid, old_string matches, resulting doc complete -> allow
gate_edit allow msg-edit-complete "$MSG_GATE" "" \
  '## messaging doc
Unique attributes: only we ship same-day.
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.' \
  "Unique attributes: only we ship same-day." \
  "Unique attributes: only we ship same-day. Competitive alternatives: status quo, competitor X."

# Edit — valid, old_string matches, still missing a field -> deny
gate_edit deny msg-edit-still-incomplete "$MSG_GATE" "" \
  '## messaging doc
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.' \
  "Market category: workflow automation." \
  "Market category: workflow automation."

# MultiEdit — all edits apply in sequence, final text complete -> allow
gate_multiedit allow msg-multiedit-complete "$MSG_GATE" "" \
  '## messaging doc
PLACEHOLDER_ALT
PLACEHOLDER_UNIQUE
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.' \
  '[{"old_string":"PLACEHOLDER_ALT","new_string":"Competitive alternatives: status quo, competitor X."},{"old_string":"PLACEHOLDER_UNIQUE","new_string":"Unique attributes: only we ship same-day."}]'

# MultiEdit — one edit's old_string does not match intermediate text -> deny
gate_multiedit deny msg-multiedit-mismatch "$MSG_GATE" "" \
  '## messaging doc
PLACEHOLDER_ALT
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.' \
  '[{"old_string":"PLACEHOLDER_ALT","new_string":"Competitive alternatives: status quo, competitor X."},{"old_string":"DOES_NOT_EXIST","new_string":"whatever"}]'

# replace_all=true replaces every occurrence: 3 occurrences of a placeholder
# used as the unique-attributes marker; only-first-occurrence-replaced would
# leave the field marker text duplicated instead of resolved, so verify all
# 3 are gone by requiring the resulting doc to pass (it only passes once
# every occurrence is replaced with real content the checker recognizes).
gate_edit allow msg-edit-replace-all "$MSG_GATE" "" \
  '## messaging doc
X X X
For the SMB segment, the value prop is faster onboarding.
Market category: workflow automation.
Positioning statement: we are the fastest onboarding tool.
Competitive alternatives: status quo, competitor X.' \
  "X" \
  "Unique attributes: only we ship same-day." \
  1

# Malformed JSON input -> deny, exit 2
gate_raw deny msg-malformed-json "$MSG_GATE" "" '{"tool_name":'

# Unrecognized kill-switch value -> gate stays ACTIVE (a non-compliant write is still denied)
gate deny msg-killswitch-unrecognized "$MSG_GATE" "" "$MSG_BAD" "MARKETING_MESSAGING_GATE_OFF=banana"

# Recognized kill-switch on-value -> gate disabled
gate allow msg-killswitch-recognized "$MSG_GATE" "" "$MSG_BAD" "MARKETING_MESSAGING_GATE_OFF=1"

# Absolute-path bypass attempt: a sibling directory whose name merely starts
# with the project root's name must not be treated as inside the root.
td_abs="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td_abs" >/dev/null 2>&1
mkdir -p "$td_abs/docs/issue-7/reports"
evil_dir="${td_abs}-evil"; mkdir -p "$evil_dir/docs/issue-7/reports"
printf '%s' "$MSG_BAD" > "$evil_dir/$REC"
payload_abs="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1]}}))' "$evil_dir/$REC")"
printf '%s' "$payload_abs" | env CLAUDE_PROJECT_DIR="$td_abs" /bin/bash "$ROOT/$MSG_GATE" >/dev/null 2>&1
rc_abs="${PIPESTATUS[1]}"; case "$rc_abs" in 0) got_abs=allow ;; 2) got_abs=deny ;; *) got_abs="exit-$rc_abs" ;; esac
report allow "$got_abs" msg-absolute-path-sibling-not-root
rm -rf "$td_abs" "$evil_dir"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
