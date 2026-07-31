#!/usr/bin/env bash
# Meant to be SOURCED by marketing/hooks/directive.sh — defines
# MARKETING_MESSAGING_FRAGMENT for concatenation into the SessionStart
# directive. Not executable on its own.
read -r -d '' MARKETING_MESSAGING_FRAGMENT <<'FRAG' || true
MESSAGING DOC — Dunford positioning canvas (April Dunford, "Obviously Awesome", 2019):
  stages: name competitive alternatives -> name unique attributes -> translate to
  per-segment value proposition -> name market category -> synthesize one-line
  positioning statement.
  done = a one-line positioning statement exists AND is traceable to a named
  competitive alternative (not merely present).
  prohibited: a generic, unattributed value-prop sentence with no named
  alternative — the whole point of Dunford's canvas is the comparison.
  Gate: marketing-messaging plugin, kill switch MARKETING_MESSAGING_GATE_OFF=1.
FRAG
