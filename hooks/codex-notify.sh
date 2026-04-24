#!/usr/bin/env bash

set -u

SOUNDS_DIR="/System/Library/Sounds"
DEFAULT_SOUND="Glass"
ACTION_SOUND="Funk"
TITLE="Codex CLI"

payload="$(cat 2>/dev/null || true)"
payload_lc="$(printf '%s' "$payload" | tr '[:upper:]' '[:lower:]')"

sound="$DEFAULT_SOUND"
message="任务已完成"

if [[ "$payload_lc" == *"approval-requested"* ]] || [[ "$payload_lc" == *"approval_requested"* ]] || [[ "$payload_lc" == *"needs approval"* ]] || [[ "$payload_lc" == *"permission"* ]] || [[ "$payload_lc" == *"confirm"* ]]; then
  sound="$ACTION_SOUND"
  message="Codex 需要你处理审批或确认"
elif [[ "$payload_lc" == *"agent-turn-complete"* ]] || [[ "$payload_lc" == *"turn complete"* ]] || [[ "$payload_lc" == *"completed"* ]] || [[ "$payload_lc" == *"finished"* ]]; then
  sound="$DEFAULT_SOUND"
  message="任务已完成"
elif [[ -n "$payload" ]]; then
  message="Codex 有新通知"
fi

sound_file="$SOUNDS_DIR/${sound}.aiff"
if [[ -f "$sound_file" ]]; then
  afplay "$sound_file" >/dev/null 2>&1 &
fi

/usr/bin/osascript <<APPLESCRIPT >/dev/null 2>&1
display notification "$(printf '%s' "$message" | sed 's/"/\\"/g')" with title "$TITLE"
APPLESCRIPT
