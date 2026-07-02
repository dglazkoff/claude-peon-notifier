#!/bin/bash
# Claude Code hook entry point: shows a notification + plays a voice line.
# Usage: notify.sh <done|wait>
#   done  -> fired by the Stop hook (task finished)     -> "Ready to work!"
#   wait  -> fired by the Notification hook (waiting)   -> one of 4 random lines
#
# Phrases come from ~/.claude/peon/phrases.sh (the active language pack); a user
# ~/.claude/peon/config.sh may override any of them and set NOTIFY_EXCLUDE.
# Sounds live in ~/.claude/peon/sounds/: done.<ext> and wait1..wait4.<ext>.

DIR="$HOME/.claude/peon"
MODE="${1:-done}"

# English defaults, used if no phrases.sh is present.
MSG_DONE="Ready to work!"
MSG_WAIT_1="Yes?"
MSG_WAIT_2="Hmm?"
MSG_WAIT_3="What you want?"
MSG_WAIT_4="Something need doing?"

# Read a KEY from a file as DATA (never sourced — the config must not be a code
# execution point that runs on every hook fire). Handles quotes + inline comments.
read_cfg() {
  local key="$1" file="$2" line val
  [[ -f "$file" ]] || return 0
  line="$(grep -E "^[[:space:]]*${key}=" "$file" 2>/dev/null | tail -1)" || return 0
  [[ -n "$line" ]] || return 0
  val="${line#*=}"
  val="${val#"${val%%[![:space:]]*}"}"           # strip leading whitespace
  case "$val" in
    '"'*) val="${val#\"}"; val="${val%%\"*}" ;;   # "quoted" -> content of first pair
    "'"*) val="${val#\'}"; val="${val%%\'*}" ;;   # 'quoted'
    *)    val="${val%%#*}"                          # unquoted: drop inline comment
          val="${val%"${val##*[![:space:]]}"}" ;;  # and trailing whitespace
  esac
  printf '%s' "$val"
}

# Resolve KEY: language pack (phrases.sh) first, user config.sh overrides it.
get_cfg() {
  local key="$1" v
  v="$(read_cfg "$key" "$DIR/config.sh")"
  [[ -n "$v" ]] && { printf '%s' "$v"; return; }
  read_cfg "$key" "$DIR/phrases.sh"
}

for key in MSG_DONE MSG_WAIT_1 MSG_WAIT_2 MSG_WAIT_3 MSG_WAIT_4; do
  v="$(get_cfg "$key")"; [[ -n "$v" ]] && printf -v "$key" '%s' "$v"
done

# Capture the hook payload (Claude Code passes event JSON on stdin). Guard on a
# terminal so a manual `notify.sh done` in a shell doesn't hang waiting on cat.
payload=""
[[ -t 0 ]] || payload="$(cat)"

# Skip notifications whose event matches NOTIFY_EXCLUDE (regex in config.sh).
# Match only the identifying fields (notification_type + message), never the whole
# payload — Stop events carry the assistant reply in last_assistant_message, so a
# reply that merely mentions the keyword must not suppress the task-finished banner.
EXCLUDE_RE="$(read_cfg NOTIFY_EXCLUDE "$DIR/config.sh")"
if [[ -n "$EXCLUDE_RE" && -n "$payload" ]]; then
  ntype="$(printf '%s' "$payload" | sed -n 's/.*"notification_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  nmsg="$(printf '%s' "$payload"  | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  printf '%s\n%s' "$ntype" "$nmsg" | grep -qiE -- "$EXCLUDE_RE" && exit 0
fi

# Pick the phrase + matching sound. "wait" chooses one of the 4 variations at random
# so the banner text and the voice line always agree.
if [[ "$MODE" == "wait" ]]; then
  n=$(( (RANDOM % 4) + 1 ))
  varname="MSG_WAIT_$n"
  MSG="${!varname}"
  SOUND_BASE="wait$n"
else
  MSG="$MSG_DONE"
  SOUND_BASE="done"
fi

# The applet reads this file to know what text to show.
printf '%s' "$MSG" > "$DIR/.msg"

# Play the matching voice line if present (wav/mp3/m4a/aiff all work).
SOUND="$(/bin/ls "$DIR"/sounds/${SOUND_BASE}.* 2>/dev/null | /usr/bin/head -1)"
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
