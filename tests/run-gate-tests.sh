#!/usr/bin/env bash
# Marketing's three methodology gates (marketing-messaging, marketing-channel,
# marketing-segment), exercised as real subprocesses against a synthetic repo.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$HERE/.." && pwd -P)"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-7/reports/marketing.md

gate() { # want name gate-script env-var-off content
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports"
  extra_env=""
  [ -n "${6:-}" ] && extra_env="$6"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$REC" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" $extra_env /bin/bash "$ROOT/$3" >/dev/null 2>&1
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
gate allow msg-no-section "$MSG_GATE" "" "no messaging content here at all"
gate allow msg-killswitch "$MSG_GATE" "" "$MSG_BAD" "MARKETING_MESSAGING_GATE_OFF=1"

# --- marketing-channel: Bullseye 3-phase test ---
CH_GATE="marketing-channel/hooks/channel-gate.sh"
CH_GOOD='## channel plan
Candidates: seo, content marketing, paid social, email.
Test criteria: 2-week cheap test per candidate, rationale documented.
Chosen channel: content marketing. we chose it based on the test.
Classification: owned and earned, minimal paid spend.'
CH_ORDER_VIOLATION='## channel plan
Test criteria: 2-week cheap test, rationale documented.
Chosen channel: content marketing. we chose it based on the test.
Classification: owned and earned.'
gate allow ch-complete "$CH_GATE" "" "$CH_GOOD"
gate deny  ch-order-violation "$CH_GATE" "" "$CH_ORDER_VIOLATION"
gate allow ch-no-section "$CH_GATE" "" "nothing relevant here"
gate allow ch-killswitch "$CH_GATE" "" "$CH_ORDER_VIOLATION" "MARKETING_CHANNEL_GATE_OFF=1"

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
gate allow seg-no-section "$SEG_GATE" "" "irrelevant content"
gate allow seg-killswitch "$SEG_GATE" "" "$SEG_BARE" "MARKETING_SEGMENT_GATE_OFF=1"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
