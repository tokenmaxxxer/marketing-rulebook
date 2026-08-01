# compliance-check.sh run record (issue #13 phase 2)

Reference invocation (core issue #75, never vendored):

```
bash "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/tests/compliance-check.sh" <hooks-dir>
```

## Before migration (structural, by inspection)

No `compliance-check.sh` run exists in this repo pre-migration (issue #13's
current-state survey confirmed no `core/` reference existed at all before
this delivery). By inspection against `compliance-check.sh`'s three
structural checks, the pre-migration gates would have FAILed:

- All three gates read a `*_OFF` kill-switch env var via a hand-rolled
  `case` statement, not `gate_kill_switch_active` → flagged.
- All three gates reconstructed `Edit`/`MultiEdit` content via their own
  `current.replace(o, n[, 1])` calls, not `gate_reconstruct_write` →
  flagged.
- `directive.sh` sourced `role-directive.sh` with no `||` guard at all
  (not even attempting `gate-lib.sh`) → the sharpest instance of the same
  root defect, though outside `compliance-check.sh`'s own `*-gate.sh`
  glob (it only scans `hooks/*-gate.sh`, not `directive.sh`).

## After migration — actual run, this delivery

```
$ bash "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/tests/compliance-check.sh" marketing-messaging/hooks
compliance-check: ok — marketing-messaging/hooks/messaging-gate.sh

$ bash "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/tests/compliance-check.sh" marketing-channel/hooks
compliance-check: ok — marketing-channel/hooks/channel-gate.sh

$ bash "${CLAUDE_PLUGIN_ROOT_CORE}/hooks/tests/compliance-check.sh" marketing-segment/hooks
compliance-check: ok — marketing-segment/hooks/segment-gate.sh
```

All three exit 0, zero FAIL. `marketing/hooks/directive.sh` is not scanned
by `compliance-check.sh` (its glob is `*-gate.sh` only) but was manually
verified fail-closed on a missing core (see `tests/run-gate-tests.sh`'s
`directive-missing-core` case): `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
nonexistent path exits 2, not silent-allow.
