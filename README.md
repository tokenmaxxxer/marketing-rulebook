# marketing-rulebook

Rulebook for the `marketing` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 어떤 메시지로 어떤 채널에 도달할지
- **use_when**: 캠페인/포지셔닝이 걸릴 때
- **produces**: messaging doc, channel plan, target segment
- **write_scope**: []
- **hand-off**: 퍼널 성과 해석은 → growth-analytics

## Install

```
claude plugin marketplace add tokenmaxxxer/marketing-rulebook
claude plugin install marketing
```

## Layout

- `marketing/.claude-plugin/plugin.json` — plugin manifest
- `marketing/hooks/hooks.json` — SessionStart wiring (role-agnostic gates now live in core, see below)
- `marketing/hooks/directive.sh` — SessionStart role directive (thin stub over core's `core_role_directive`)
- `marketing/hooks/lib/role-config.sh` — this role's record-fields/record-path config, consumed by core's record-fields-gate canon
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The record-fields gate, the commit trailer gate, and the s21 handbook-sync
gate no longer have role-local copies in this repo — they are intended to
be registered role-agnostically in `core/hooks/` (core issue #66).
Warrant-hunt coverage for this role is intended to come from core's
`warrant/` plugin (core issue #63); this rulebook carries no local hunt
agent. **As of this writing, no `core/` tree exists in this repository**
— these are forward-looking references to a shared core canon that has
not landed here yet (see also core issue #72, `core/hooks/lib/gate-lib.sh`,
referenced by this rulebook's own methodology gates' fail-closed/kill-switch/
path-resolution helpers, which remain local per-script implementations of
the same contract pending that landing).

- `marketing-messaging/`, `marketing-channel/`, `marketing-segment/` — the
  three per-methodology plugins that gate marketing's `messaging doc`,
  `channel plan`, and `target segment` record fields respectively (issue
  #7). Each has its own `hooks/*-gate.sh` PreToolUse gate and README.
- `tests/run-gate-tests.sh` — shared test suite for all three methodology
  gates above.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
