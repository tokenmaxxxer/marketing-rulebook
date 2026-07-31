#!/usr/bin/env bash
# SessionStart: marketing's role directive — thin stub over core canon.
# Shared mechanics (kill-switch, CLAUDE_ROLE gate, fail-closed trap,
# directive emission) live in core_role_directive; only this role's own
# directive content, plus concatenation of the three methodology plugins'
# directive fragments, is defined here (per docs/issue-7 plugin-set design:
# marketing itself owns orchestration only, not per-field methodology text).
set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/../core/hooks/lib/role-directive.sh"

# Each methodology plugin is self-contained and sources into this role's
# directive rather than being vendored here. A missing fragment (plugin not
# installed) degrades to an empty string, not a hard failure — this stub
# still emits the phase-1/orchestration content below on its own.
MARKETING_MESSAGING_FRAGMENT=""
MARKETING_CHANNEL_FRAGMENT=""
MARKETING_SEGMENT_FRAGMENT=""
# shellcheck disable=SC1091
[ -f "${CLAUDE_PLUGIN_ROOT}/../marketing-messaging/hooks/directive-fragment.sh" ] && \
  source "${CLAUDE_PLUGIN_ROOT}/../marketing-messaging/hooks/directive-fragment.sh"
# shellcheck disable=SC1091
[ -f "${CLAUDE_PLUGIN_ROOT}/../marketing-channel/hooks/directive-fragment.sh" ] && \
  source "${CLAUDE_PLUGIN_ROOT}/../marketing-channel/hooks/directive-fragment.sh"
# shellcheck disable=SC1091
[ -f "${CLAUDE_PLUGIN_ROOT}/../marketing-segment/hooks/directive-fragment.sh" ] && \
  source "${CLAUDE_PLUGIN_ROOT}/../marketing-segment/hooks/directive-fragment.sh"

core_role_directive "marketing" <<DIRECTIVE
YOU DECIDE: 어떤 메시지로 어떤 채널에 도달할지

USE_WHEN: 캠페인/포지셔닝이 걸릴 때

PRODUCES (required record fields, each machine-gated by its own plugin):
  messaging doc  -> marketing-messaging plugin (Dunford positioning canvas)
  channel plan   -> marketing-channel plugin (Bullseye 3-phase test)
  target segment -> marketing-segment plugin (STP + ICP)

$MARKETING_MESSAGING_FRAGMENT

$MARKETING_CHANNEL_FRAGMENT

$MARKETING_SEGMENT_FRAGMENT

WRITE_SCOPE: []

PHASE-1 CHECKLIST (proposal-writing norm, issue #1 §a — text guidance only,
no gate enforces phase-1 document structure): problem/goal statement;
reference to the current-state survey (this role's own scout protocol, per
core's scout plugin); named methodology citation for each field above; the
required-sections checklist itself, restated; evidence-citation for any
claim; [ASSUMPTION] flagging for anything not confirmed; a status header
naming phase-1 vs phase-2. Skipping the survey-reference step, or presenting
[ASSUMPTION]-worthy content as confirmed fact, are both prohibited shortcuts
for this role's own proposals.

HAND-OFF: 퍼널 성과 해석은 → growth-analytics

BOUNDARY CASE: if the work in front of you drifts outside \`decides\` above,
stop and hand off per the arrow — do not silently absorb another role's
scope. Record the hand-off point in this role's record before opening the
next role's session.

RECORD: docs/issue-<n>/reports/marketing.md, phase-gated per contract v3 s19
(phase-1 homes only pre-Approve; this record is phase-2 output).
DIRECTIVE
