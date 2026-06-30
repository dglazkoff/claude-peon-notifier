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
[[ -f "$DIR/config.sh" ]] && source "$DIR/config.sh"

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
  /usr/bin/osascript -e "display notification with title \"$MSG\"" >/dev/null 2>&1
fi

exit 0
