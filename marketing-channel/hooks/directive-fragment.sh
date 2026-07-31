#!/usr/bin/env bash
read -r -d '' MARKETING_CHANNEL_FRAGMENT <<'FRAG' || true
CHANNEL PLAN — Bullseye Framework 3-phase test (Gabriel Weinberg & Justin Mares,
  "Traction", 2015):
  stages: brainstorm candidates broadly -> cheap-test each -> select with rationale.
  done = a chosen channel exists with a stated test rationale AND a visible
  candidate list in the same field.
  prohibited: selecting a channel without a stated test rationale — Bullseye's
  whole point is test-before-commit, not pre-existing preference. A chosen
  channel with no candidate list shown is an ordering violation.
  Gate: marketing-channel plugin, kill switch MARKETING_CHANNEL_GATE_OFF=1.
FRAG
