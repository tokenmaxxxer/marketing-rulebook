#!/usr/bin/env bash
read -r -d '' MARKETING_SEGMENT_FRAGMENT <<'FRAG' || true
TARGET SEGMENT — STP + ICP (Kotler & Keller, "Marketing Management"; standard
  B2B/B2C ICP practice; JTBD as optional behavioral lens):
  stages: name segmentation criteria used -> define ICP concretely -> state
  targeting rationale against alternative segments.
  done = the ICP definition is a concrete profile, not a bare demographic
  label — requires more than one criterion type or an explicit "ICP:" block.
  prohibited: a demographic label alone with no rationale for why this
  segment over others.
  Gate: marketing-segment plugin, kill switch MARKETING_SEGMENT_GATE_OFF=1.
FRAG
