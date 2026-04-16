---
name: set-notification
description: Interactive wizard to configure Claude Code notification sounds on macOS. Checks existing config, guides through sound and TTS phrase selection, writes only to ~/.claude/settings.json. Trigger: /set-notification
trigger: /set-notification
---

# /set-notification

Interactive wizard to configure Claude Code notification sounds on macOS. Re-run anytime to check or update your configuration.

---

## Steps (Claude follows this flow)

### Step 1 — Scan Current Config

Run the following script and display the results:

```bash
f="$HOME/.claude/settings.json"
echo "=== settings.json ==="
python3 -c "
import json, os
path = os.path.expanduser('~/.claude/settings.json')
try:
    d = json.load(open(path))
    hooks = d.get('hooks', {})
    for ev in ['Stop', 'Notification', 'SubagentStop']:
        cmds = [h['command'] for g in hooks.get(ev, []) for h in g.get('hooks', [])
                if any(k in h.get('command','') for k in ['afplay','say','notification-sound'])]
        if cmds:
            print(f'  {ev}: ✓  {cmds[0][:80]}')
        else:
            print(f'  {ev}: ✗  not configured')
except FileNotFoundError:
    print('  (~/.claude/settings.json not found)')
except Exception as e:
    print(f'  (parse error: {e})')
" 2>/dev/null
```

### Step 2 — Ask User

> **Note**: All questions require explicit input. Pressing Enter alone has no effect in Claude Code.

---

**Q1: What would you like to do?**

Prompt: `What would you like to do? [auto=quick install with defaults / y=custom setup / off=disable all sounds]:`

- `auto` — **run Auto Mode** (see below), no further prompts
- `y` — continue to configure sounds interactively
- `off` — remove all sound hooks (silent mode)

---

**Q2 (if Q1=y): Which events to update?**

Show current config summary, then prompt:

```
Current config:
  1. Stop        → ...
  2. Notification → ...
  3. SubagentStop → ...

Enter numbers to update, comma-separated [1 / 2 / 3 / 1,2 / all]:
```

---

**Q3 (only when Notification is selected): Notification mode**

First run this Python availability check:

```bash
PYTHON_BIN=""
for py in python3 python; do
  full=$(command -v "$py" 2>/dev/null)
  if [ -n "$full" ] && "$full" -c "import json, subprocess, sys" 2>/dev/null; then
    PYTHON_BIN="$full"
    break
  fi
done
echo "PYTHON_BIN=$PYTHON_BIN"
```

**If Python is available**, ask the user to choose a mode:

```
Notification mode:
  1. Simple  — one sound + one phrase for all notifications
               e.g. Funk.aiff + say 'Attention Need'
  2. Smart   — different sound per scenario (Python required, script auto-created)
               permission_prompt  → Hero.aiff  + say 'Permission Need'
               elicitation_dialog → Hero.aiff  + say 'Confirmation Need'
               idle_prompt        → Funk.aiff  (sound only, no say)

Enter [1/2]:
```

- Choose `1` → proceed to Q3a (configure phrase) then Q4a (configure sound)
- Choose `2` → proceed to Q3b (idle_prompt voice style), then script auto-written in Step 3

---

**Q3b (Smart mode only): idle_prompt voice style**

```
idle_prompt (waiting for text input) voice style:
  1. Silent   — Funk.aiff sound only, no TTS  (default)
  2. StarCraft — Funk.aiff + random StarCraft Terran quote (13 lines)
  3. Custom   — Funk.aiff + say '<your phrase>'

Enter [1/2/3]:
```

- Choose `1` → `idle_prompt` uses `("Funk", None)` — sound only
- Choose `2` → `idle_prompt` uses `("Funk", random.choice(STARCRAFT_IDLE))` — random StarCraft quote from 13 Terran unit lines
- Choose `3` → ask for custom phrase, uses `("Funk", "<phrase>")`

After Q3b, skip Q3a/Q4a and jump to Q5

**If Python is not available**, skip this question and use simple mode only:

```
⚠ Smart mode unavailable (Python not found). Using simple mode.
```

---

**Q3a (simple mode / non-Notification events): TTS phrase**

Prompt format (read current value from the settings file first):
```
Stop — TTS phrase (current: "Task Finished" / none if not set)
Enter new phrase, or type keep to leave unchanged, or off to disable TTS:
```

- Enter a new phrase (English recommended — non-English TTS quality varies)
- `keep` — leave the current phrase unchanged
- `off` — disable TTS for this event

---

**Q4a (per selected event): Sound file**

Prompt format:
```
Stop — sound (current: Glass)
Options: 1=Glass  2=Ping  3=Hero  4=Tink  5=Pop
Enter number or name, or keep to leave unchanged:
```

Notification simple mode options: `1=Funk  2=Basso  3=Sosumi  4=Bottle`

---

**Q5: Preview**

Prompt: `Play a preview of the configured sounds? [y/n]:`

If `y`, run:
```bash
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & say 'Task Done!'
sleep 2
afplay /System/Library/Sounds/Funk.aiff 2>/dev/null & say 'Attention Need'
```

---

**Q6: Confirm**

Show a preview of all commands to be written, then prompt: `Write configuration to ~/.claude/settings.json? [y/n]:`

---

### Auto Mode (Q1=auto)

No further questions. Execute the following steps silently and show a completion summary at the end.

**Auto Step 1 — Detect Python**

```bash
PYTHON_BIN=""
for py in python3 python; do
  full=$(command -v "$py" 2>/dev/null)
  if [ -n "$full" ] && "$full" -c "import json, subprocess, sys" 2>/dev/null; then
    PYTHON_BIN="$full"; break
  fi
done
```

**Auto Step 2 — Default config plan**

| Event | Python available | Python not available |
|---|---|---|
| Stop | `afplay /System/Library/Sounds/Glass.aiff 2>/dev/null` | same |
| Notification | `$PYTHON_BIN ~/.claude/hooks/notification-sound.py` | `afplay /System/Library/Sounds/Funk.aiff 2>/dev/null & say 'Attention Need'` |
| SubagentStop | `afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & say 'Subagent Finished'` | same |

**Auto Step 3 — Write notification-sound.py (Python only)**

Use the Write tool to create `~/.claude/hooks/notification-sound.py`:

```bash
mkdir -p ~/.claude/hooks
```

```python
#!/usr/bin/env python3
"""
Claude Code Notification smart dispatcher.
Plays different sounds based on notification_type in the hook payload.
Auto-generated by /set-notification skill.
"""
import json
import subprocess
import sys

SOUNDS = "/System/Library/Sounds"

TYPE_MAP = {
    "permission_prompt":  ("Hero", "Permission Need"),
    "elicitation_dialog": ("Hero", "Confirmation Need"),
    "idle_prompt":        ("Funk", None),
}
DEFAULT = ("Funk", "Attention Need")

try:
    data = json.load(sys.stdin)
    ntype = data.get("notification_type", "")
except Exception:
    ntype = ""

sound, phrase = TYPE_MAP.get(ntype, DEFAULT)

subprocess.Popen(["afplay", f"{SOUNDS}/{sound}.aiff"], stderr=subprocess.DEVNULL)
if phrase:
    subprocess.Popen(["say", phrase])
```

**Auto Step 4 — Write ~/.claude/settings.json**

Load, update (preserving all other settings), and write back using Python. Replace the sound hooks for Stop, Notification, SubagentStop with the defaults from Step 2.

**Auto Step 5 — Validate**

```bash
python3 -m json.tool ~/.claude/settings.json > /dev/null 2>&1 && echo "✓ JSON valid" || echo "✗ JSON ERROR"
```

**Auto Step 6 — Done**

Show a summary of what was written, then output:

```
✅ Done! Please restart Claude Code to activate notification sounds.

Configured:
  Stop        → Glass.aiff  (plays when Claude finishes a response)
  Notification → smart mode / simple mode  (plays when Claude needs your attention)
  SubagentStop → Glass.aiff + say 'Subagent Finished'
```

---

### Step 3 — Write Config

Generate the command string for each event:

| Combination | Command format |
|---|---|
| Sound + say | `afplay /System/Library/Sounds/X.aiff 2>/dev/null & say 'TEXT'` |
| Sound only | `afplay /System/Library/Sounds/X.aiff 2>/dev/null` |
| Say only | `say 'TEXT'` |
| Disable | Remove the sound hook entry for this event |
| Notification smart mode | `$PYTHON_BIN ~/.claude/hooks/notification-sound.py` |

**When writing Notification smart mode**:

**Step 3a** — Use the Write tool to create `~/.claude/hooks/notification-sound.py`.

Generate the script based on the user's Q3b choice for `idle_prompt` voice style:

- **Q3b=1 (Silent)** — `idle_prompt` line: `"idle_prompt": ("Funk", None),`
- **Q3b=2 (StarCraft)** — add `import random` and `STARCRAFT_IDLE` list, `idle_prompt` line: `"idle_prompt": ("Funk", random.choice(STARCRAFT_IDLE)),`
- **Q3b=3 (Custom)** — `idle_prompt` line: `"idle_prompt": ("Funk", "<user phrase>"),`

Template (adapt `idle_prompt` line per choice above):

```python
#!/usr/bin/env python3
"""
Claude Code Notification smart dispatcher.
Plays different sounds based on notification_type in the hook payload.
Auto-generated by /set-notification skill.
"""
import json
import random  # only needed for StarCraft mode; omit for Silent/Custom
import subprocess
import sys

SOUNDS = "/System/Library/Sounds"

# StarCraft Terran quotes — only include this block for StarCraft mode (Q3b=2)
STARCRAFT_IDLE = [
    "It's a wonderful day!",                                    # SCV
    "I'm locked in here with a bunch of perverts!",            # SCV
    "What, you ran out of Marines?",                           # SCV
    "You want a piece of me, boy?",                            # Marine
    "How do I get out of this chicken-shit outfit?",           # Marine
    "I come in peace... usually.",                             # Marine
    "I'm about to drop the hammer and dispense some justice!", # Siege Tank
    "I love the smell of singed Zerg in the morning.",         # Siege Tank
    "Abandon ship! Dammit, can't find the buttons!",           # Battlecruiser
    "I see dead people.",                                      # Ghost
    "Nuclear launch detected.",                                # Ghost
    "The doctor is in.",                                       # Medic
    "I've already diagnosed your condition... INFECTED!",      # Medic
]

# notification_type → (sound file stem, say phrase or None)
TYPE_MAP = {
    "permission_prompt":  ("Hero",  "Permission Need"),
    "elicitation_dialog": ("Hero",  "Confirmation Need"),
    "idle_prompt":        ("Funk",  None),  # ← adapt per Q3b choice
}
DEFAULT = ("Funk", "Attention Need")

try:
    data = json.load(sys.stdin)
    ntype = data.get("notification_type", "")
except Exception:
    ntype = ""

sound, phrase = TYPE_MAP.get(ntype, DEFAULT)

subprocess.Popen(["afplay", f"{SOUNDS}/{sound}.aiff"], stderr=subprocess.DEVNULL)
if phrase:
    subprocess.Popen(["say", phrase])
```

**Step 3b** — Ensure the hooks directory exists:
```bash
mkdir -p ~/.claude/hooks
```

**Step 3c** — Use the detected `$PYTHON_BIN` absolute path as the hook command:
```
$PYTHON_BIN ~/.claude/hooks/notification-sound.py
```

**Writing principle**: only modify `~/.claude/settings.json` if it exists. Use Python to load, update, and write back:

```bash
python3 -c "
import json, os

path = os.path.expanduser('~/.claude/settings.json')
if not os.path.exists(path):
    print('File not found, skipping.')
    exit()

with open(path) as f:
    d = json.load(f)

# --- apply user's chosen hook commands here ---
# Example for Stop:
# d.setdefault('hooks', {}).setdefault('Stop', [{}])
# d['hooks']['Stop'][0].setdefault('hooks', [])
# ... update or replace the sound hook entry ...

with open(path, 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
print('Written.')
"
```

### Step 4 — Validate

After writing, run JSON syntax check:

```bash
f="$HOME/.claude/settings.json"
if [ -f "$f" ]; then
  echo -n "settings.json: "
  python3 -m json.tool "$f" > /dev/null 2>&1 && echo "✓ valid" || echo "✗ JSON ERROR"
fi
```

---

## Reference

### Sound File Guide

| File | Character | Good for |
|---|---|---|
| `Glass.aiff` | Crisp glass tap | Stop / SubagentStop |
| `Funk.aiff` | Low-toned alert | Notification — needs action |
| `Ping.aiff` | Short high ping | Backup |
| `Hero.aiff` | Uplifting completion | Stop alternative |
| `Tink.aiff` | Minimal tick | Low-distraction |
| `Pop.aiff` | Soft pop | Low-distraction |
| `Basso.aiff` | Deep bass | Notification alternative |
| `Sosumi.aiff` | Classic Mac alert | Strong reminder |
| `Bottle.aiff` | Bottle blow | — |

Preview any sound:
```bash
afplay /System/Library/Sounds/Glass.aiff
```

### Event Reference

| Event | Fires when | Simple mode default | Smart mode |
|---|---|---|---|
| `Stop` | Claude finishes a response | Glass.aiff + say 'Task Finished' | — |
| `Notification` | Claude needs permission/confirmation/input | Funk.aiff + say 'Attention Need' | `notification-sound.py` |
| `SubagentStop` | A sub-agent completes its task | Glass.aiff + say 'Subagent Finished' | — |

**Notification sub-types** (smart mode):

| `notification_type` | When | Sound | Say |
|---|---|---|---|
| `permission_prompt` | Tool permission dialog | Hero.aiff | Permission Need |
| `elicitation_dialog` | Waiting for confirmation | Hero.aiff | Confirmation Need |
| `idle_prompt` | Waiting for text input | Funk.aiff | configurable: silent (default) / random StarCraft quote / custom phrase |
| _(fallback)_ | Any other case | Funk.aiff | Attention Need |

### Key Config Details

**`async: true`** (required): sound plays in background without blocking Claude Code. Without it, Claude Code waits ~1-2 seconds for `afplay` to finish before continuing.

**`&` operator**: `afplay ... & say '...'` starts both processes simultaneously. Without `&`, they run sequentially.

**Compatibility**: `Glass.aiff` has existed since macOS 10.2 (2002) and works through macOS 26.x. `say` is a built-in TTS command, always available on macOS.

### FAQ

**No sound after configuring?**
1. Check JSON syntax (commas, brackets) in `~/.claude/settings.json`
2. Confirm `"async": true` is present
3. Check system volume isn't muted
4. Restart Claude Code

**Use a custom audio file?**
```json
"command": "afplay /path/to/your.mp3 2>/dev/null & say 'Done'"
```
`afplay` supports `.aiff`, `.mp3`, `.wav`, `.m4a`.

**Adjust volume?**
```bash
afplay /System/Library/Sounds/Glass.aiff -v 0.5   # 0.0–1.0
```

**Linux / Windows?**
- Linux: replace `afplay` with `paplay` or `aplay`
- Windows: `powershell -c (New-Object Media.SoundPlayer 'C:\Windows\Media\ding.wav').PlaySync()`
