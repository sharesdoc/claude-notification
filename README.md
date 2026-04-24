# set-notification

A Claude Code skill that interactively configures notification sounds on macOS — so you can hear when Claude finishes a task, needs your permission, or is waiting for your input.

This repository now also includes a Codex CLI notification hook for macOS, so Codex can play different sounds for task completion and attention-needed events.

## Demo

Run `/set-notification` in Claude Code. Type `auto` for a one-shot install, or `y` for interactive setup:

```
Current config:
  Stop        ✓  afplay Glass.aiff 2>/dev/null
  Notification ✓  python3 ~/.claude/hooks/notification-sound.py
  SubagentStop ✓  afplay Glass.aiff 2>/dev/null & say 'Subagent Finished'

What would you like to do? [auto=quick install with defaults / y=custom setup / off=disable all sounds]:
> auto

✅ Done! Please restart Claude Code to activate notification sounds.

Configured:
  Stop        → Glass.aiff  (plays when Claude finishes a response)
  Notification → smart mode  (plays when Claude needs your attention)
  SubagentStop → Glass.aiff + say 'Subagent Finished'
```

## What It Configures

Claude Code fires three hook events relevant to sound notifications:

| Event | When it fires | Recommended sound |
|---|---|---|
| `Stop` | Claude finishes a response | Glass.aiff — crisp, task done |
| `Notification` | Claude needs your permission / confirmation / input | Funk.aiff — attention needed |
| `SubagentStop` | A sub-agent completes its task | Glass.aiff — task done |

### Two Modes for `Notification`

**Simple mode** — one sound + one phrase for all notification types:
```
afplay /System/Library/Sounds/Funk.aiff 2>/dev/null & say 'Attention Need'
```

**Smart mode** (requires Python) — different sounds per scenario:

| `notification_type` | When | Sound | Say |
|---|---|---|---|
| `permission_prompt` | Tool permission dialog | Hero.aiff | "Permission Need" |
| `elicitation_dialog` | Waiting for confirmation | Hero.aiff | "Confirmation Need" |
| `idle_prompt` | Waiting for text input | Funk.aiff | configurable (see below) |

**`idle_prompt` voice options** (choose during `/set-notification` custom setup):
- **Silent** (default) — sound only, no TTS
- **StarCraft** — random Terran unit quote (13 lines: Marine, SCV, Siege Tank, Ghost, Medic, Battlecruiser)
- **Custom** — your own phrase

Smart mode auto-creates `~/.claude/hooks/notification-sound.py` — no manual setup needed.

**How it works**: When Claude Code fires the `Notification` event, it writes a JSON payload to the hook script's stdin, including a `notification_type` field that identifies the exact scenario. The script reads this field and dispatches the right sound automatically:

```
Claude Code  →  stdin: {"notification_type": "permission_prompt", ...}
                          ↓
notification-sound.py  →  TYPE_MAP lookup  →  Hero.aiff + say "Permission Need"
```

No extra configuration needed — the classification happens automatically based on what Claude Code sends.

## Requirements

- macOS (uses `afplay` and `say`)
- [Claude Code](https://claude.ai/code) CLI installed
- Python 3 (optional, for smart Notification mode — system Python works)

## Installation

Copy the skill file to your Claude Code commands directory:

```bash
cp set-notification.md ~/.claude/commands/set-notification.md
```

That's it. The skill is now available in Claude Code.

## Codex CLI

For Codex CLI on macOS, install the bundled notify hook:

```bash
mkdir -p ~/.codex
install -m 755 hooks/codex-notify.sh ~/.codex/notify.sh
```

Then add the following to `~/.codex/config.toml`:

```toml
notify = ["/Users/johnson/.codex/notify.sh"]

[tui]
notifications = ["agent-turn-complete", "approval-requested"]
notification_condition = "always"
notification_method = "auto"
```

Behavior:
- `Glass.aiff` for task completion
- `Funk.aiff` for approval / confirmation style events when the payload indicates attention is needed
- TUI notifications remain enabled for `agent-turn-complete` and `approval-requested`

## Usage

In any Claude Code session, type:

```
/set-notification
```

**Quick install (auto mode):** type `auto` when prompted — applies recommended defaults, no further questions, done in seconds.

**Custom setup:** type `y` to configure each event interactively:
1. Choose which events to update (Stop / Notification / SubagentStop)
2. Set TTS phrase and sound per event
3. Choose simple or smart Notification mode (if Python available)
4. Preview before writing

Both modes write to `~/.claude/settings.json` and validate JSON syntax when done.

## Available Sounds

macOS system sounds in `/System/Library/Sounds/`:

| File | Character | Good for |
|---|---|---|
| `Glass.aiff` | Crisp glass tap | Stop / SubagentStop |
| `Funk.aiff` | Low-toned alert | Notification (needs action) |
| `Basso.aiff` | Deep bass | Notification alternative |
| `Ping.aiff` | Short high ping | Backup |
| `Hero.aiff` | Uplifting completion | Stop alternative |
| `Tink.aiff` | Minimal tick | Low-distraction |
| `Pop.aiff` | Soft pop | Low-distraction |
| `Bottle.aiff` | Bottle blow | — |
| `Sosumi.aiff` | Classic Mac alert | Strong reminder |

Preview any sound:
```bash
afplay /System/Library/Sounds/Glass.aiff
```

## How It Works

Claude Code executes hook commands at lifecycle events. This skill configures:

```json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff 2>/dev/null", "async": true }] }],
    "Notification": [{ "hooks": [{ "type": "command", "command": "python3 ~/.claude/hooks/notification-sound.py", "async": true }] }],
    "SubagentStop": [{ "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & say 'Subagent Finished'", "async": true }] }]
  }
}
```

Key details:
- **`async: true`** — sound plays in background, doesn't block Claude Code
- **`&` operator** — `afplay ... & say '...'` plays sound and speech simultaneously
- **`2>/dev/null`** — suppresses afplay errors (e.g., if sound file is missing)

## FAQ

**No sound after configuring?**
1. Check JSON syntax in `~/.claude/settings.json` (commas, brackets)
2. Confirm `"async": true` is set
3. Check system volume isn't muted
4. Restart Claude Code

**Use a custom audio file?**
```json
"command": "afplay /path/to/your.mp3 2>/dev/null & say 'Done'"
```
`afplay` supports `.aiff`, `.mp3`, `.wav`, `.m4a`.

**Adjust volume?**
```bash
afplay /System/Library/Sounds/Glass.aiff -v 0.5   # range: 0.0–1.0
```

**Linux / Windows?**
- Linux: replace `afplay` with `paplay` or `aplay`
- Windows: `powershell -c (New-Object Media.SoundPlayer 'C:\Windows\Media\ding.wav').PlaySync()`

## License

MIT
