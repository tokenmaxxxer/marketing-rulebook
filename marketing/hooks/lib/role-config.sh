# marketing role config, intended for consumption by core's
# record-fields-gate canon once it lands (core issue #66/#72).
# [ASSUMPTION] currently unused: no core/ tree exists in this repository as
# of issue #10 phase 2 — re-verify the real consumption point once core
# lands before removing this comment.
RECORD_FIELDS_REQUIRED=("messaging-doc" "channel-plan" "target-segment")
RECORD_FIELDS_RECORD_PATH="reports/marketing.md"
RECORD_FIELDS_TERMINAL_STATES=()   # no role-specific terminal loop_state today
