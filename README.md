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
- `marketing/hooks/directive.sh` — SessionStart role directive (thin stub over core's `core_role_directive`), guarded-sourcing `core/hooks/lib/role-directive.sh`
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The record-fields gate, the commit trailer gate, and the s21 handbook-sync
gate no longer have role-local copies in this repo — they are registered
role-agnostically in `core/hooks/` (core issue #66). Warrant-hunt coverage
for this role comes from core's `warrant/` plugin (core issue #63); this
rulebook carries no local hunt agent. This role's own methodology gates
(below) source `core/hooks/lib/gate-lib.sh` by reference — resolved via
`${CLAUDE_PLUGIN_ROOT_CORE:-${CLAUDE_PLUGIN_ROOT}/../core}` — for their
fail-closed trap, kill-switch convention, and Bash-write-target detection,
per `docs/handbooks/gate-house-standard.md`; core is never vendored into
this repo. A previous `marketing/hooks/lib/role-config.sh` stub, written
against an unverified guess at core's record-fields-gate shape before core
landed, has been retired — role-record-fields config is core's canon to
own once that integration is scoped as its own piece of work.

- `marketing-messaging/`, `marketing-channel/`, `marketing-segment/` — the
  three per-methodology plugins that gate marketing's `messaging doc`,
  `channel plan`, and `target segment` record fields respectively (issue
  #7). Each has its own `hooks/*-gate.sh` PreToolUse gate and README.
- `tests/run-gate-tests.sh` — shared test suite for all three methodology
  gates above.

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
