#!/bin/bash
# Claude Code hook entry point: shows a notification + plays a voice line.
# Usage: notify.sh <done|wait>
#   done  -> fired by the Stop hook (task finished)
#   wait  -> fired by the Notification hook (waiting for permission/input)
#
# Phrases are overridable via ~/.claude/peon/config.sh (MSG_DONE / MSG_WAIT).
# Sounds: drop done.<ext> / wait.<ext> (mp3/wav/m4a/aiff) into ~/.claude/peon/.

DIR="$HOME/.claude/peon"
MODE="${1:-done}"

# Defaults (Warcraft III peon vibe). Override in config.sh.
MSG_DONE="Готов вкалывать"
MSG_WAIT="Че надо, хозяин?"

# Read overrides from config.sh as DATA, not by sourcing it — the config file
# must never become a code-execution point that runs on every hook fire.
read_cfg() {
  local key="$1" file="$DIR/config.sh" line val
  [[ -f "$file" ]] || return 0
  line="$(grep -E "^[[:space:]]*${key}=" "$file" 2>/dev/null | tail -1)" || return 0
  [[ -n "$line" ]] || return 0
  val="${line#*=}"
  # strip one layer of surrounding single or double quotes
  val="${val%\"}"; val="${val#\"}"
  val="${val%\'}"; val="${val#\'}"
  printf '%s' "$val"
}
cfg="$(read_cfg MSG_DONE)"; [[ -n "$cfg" ]] && MSG_DONE="$cfg"
cfg="$(read_cfg MSG_WAIT)"; [[ -n "$cfg" ]] && MSG_WAIT="$cfg"

case "$MODE" in
  wait) MSG="$MSG_WAIT"; SOUND_BASE="wait" ;;
  *)    MSG="$MSG_DONE"; SOUND_BASE="done" ;;
esac

# The applet reads this file to know what text to show.
printf '%s' "$MSG" > "$DIR/.msg"

# Play the matching voice line if present (mp3/wav/m4a/aiff all work).
SOUND="$(/bin/ls "$DIR"/${SOUND_BASE}.* 2>/dev/null | /usr/bin/head -1)"
if [[ -n "$SOUND" ]]; then
  /usr/bin/afplay "$SOUND" >/dev/null 2>&1 &
fi

# Post the notification via the app bundle (so its icon = your image).
if [[ -d "$DIR/Peon.app" ]]; then
  /usr/bin/open "$DIR/Peon.app"
else
  # Fallback before the app is built: native notification, terminal icon.
  # Pass the text as an argv item (not string interpolation) so quotes/specials
  # in the phrase can't break the script or inject AppleScript.
  /usr/bin/osascript -e 'on run argv' -e 'display notification with title (item 1 of argv)' -e 'end run' "$MSG" >/dev/null 2>&1
fi

exit 0
