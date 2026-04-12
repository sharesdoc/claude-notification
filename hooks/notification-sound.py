#!/usr/bin/env python3
"""
Claude Code Notification smart dispatcher.

Reads the hook payload from stdin and plays different sounds + TTS
based on the notification_type field.

notification_type values:
  permission_prompt  — Claude is asking for tool permission
  elicitation_dialog — Claude is waiting for user confirmation
  idle_prompt        — Claude is waiting for user text input

This script is auto-created by the /set-notification skill when you
choose smart mode. You can also install it manually:
  cp hooks/notification-sound.py ~/.claude/hooks/notification-sound.py

Then add to ~/.claude/settings.json:
  "Notification": [{
    "hooks": [{
      "type": "command",
      "command": "python3 ~/.claude/hooks/notification-sound.py",
      "async": true
    }]
  }]
"""
import json
import subprocess
import sys

SOUNDS = "/System/Library/Sounds"

# Customize this mapping to change sounds and phrases per scenario.
# Format: "notification_type": ("SoundFileStem", "TTS phrase")
TYPE_MAP = {
    "permission_prompt":  ("Hero",  "Permission Need"),
    "elicitation_dialog": ("Hero",  "Confirmation Need"),
    "idle_prompt":        ("Funk",  "Choice Need"),
}
DEFAULT = ("Funk", "Attention Need")

data = json.load(sys.stdin)
ntype = data.get("notification_type", "")
sound, phrase = TYPE_MAP.get(ntype, DEFAULT)

subprocess.Popen(["afplay", f"{SOUNDS}/{sound}.aiff"], stderr=subprocess.DEVNULL)
subprocess.Popen(["say", phrase])
