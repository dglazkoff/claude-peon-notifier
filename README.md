# claude-peon 🪓

Native macOS notifications for [Claude Code](https://www.anthropic.com/claude-code) hooks,
with a **custom icon** and a **voice line** — Warcraft III peon style.

- **Task finished** (`Stop` hook) → banner **“Готов вкалывать”** + `done` sound
- **Waiting for permission / input** (`Notification` hook) → banner **“Че надо, хозяин?”** + `wait` sound

Built with **only the tools that ship with macOS** — no `terminal-notifier`, no Python, no jq.
The notification icon is the peon because the notification is posted by a tiny `.app`
bundle whose icon is your image. That’s the *real* native way macOS shows a custom icon.

## Install

### Homebrew (tap)
```bash
brew install dglazkoff/tap/claude-peon-notifier
claude-peon install
```

### Clone + one command
```bash
git clone https://github.com/dglazkoff/claude-peon-notifier.git
cd claude-peon-notifier
./install.sh
```

### curl one-liner
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dglazkoff/claude-peon-notifier/main/install.sh)
```

> The installer copies scripts to `~/.claude/peon`, builds `Peon.app`, and merges the
> `Stop` / `Notification` hooks into `~/.claude/settings.json` (idempotent — safe to re-run).

## One manual step (macOS requirement)

macOS won’t show banners until you allow them for the app:

**System Settings → Notifications → Peon → Allow Notifications, style Banners or Alerts.**

The installer opens this pane for you. Then verify:
```bash
claude-peon test
```

## Add your assets

Assets are **not** bundled (Warcraft art/audio is copyrighted). Drop your own into
`~/.claude/peon`:

| file | purpose |
|---|---|
| `peon.png` or `peon.jpg` | notification icon |
| `done.mp3` (or `.wav/.m4a/.aiff`) | sound when a task finishes |
| `wait.mp3` (or `.wav/.m4a/.aiff`) | sound when waiting for permission |

Then rebuild the icon:
```bash
claude-peon build
```

## Customize the phrases

Edit `~/.claude/peon/config.sh`:
```bash
MSG_DONE="Готов вкалывать"
MSG_WAIT="Че надо, хозяин?"
```

## Commands
```
claude-peon install     Copy scripts, build the app, wire the hooks
claude-peon build       Rebuild Peon.app from the current image
claude-peon test        Fire both notifications
claude-peon status      Show what's installed
claude-peon uninstall   Remove hooks and ~/.claude/peon
```

## How it works

1. A Claude Code hook (`Stop` / `Notification`) runs `notify.sh done|wait`.
2. `notify.sh` writes the phrase to `~/.claude/peon/.msg`, plays the matching sound with
   `afplay`, and `open`s `Peon.app`.
3. `Peon.app` (an AppleScript applet built by `build-app.sh`) reads `.msg` and posts a
   native notification. Because it’s its own bundle with your icon, macOS shows the peon.

## Gotchas this project handles for you

- **No bundle id = silent failure.** `osacompile` applets ship without `CFBundleIdentifier`;
  without one macOS drops every notification. The build adds one, re-signs (`codesign`), and
  re-registers with Launch Services (`lsregister`).
- **Banners default to off.** macOS delivers to Notification Center but shows no banner until
  you enable it (the one manual step above).
- **`iconutil` is flaky.** It fails with *“Failed to generate ICNS”* on some JPEGs, so the icon
  is built via `sips` direct conversion instead.
- **Icon caching.** The build flushes `usernoted` so a new image shows immediately.

## Uninstall
```bash
claude-peon uninstall      # removes hooks + ~/.claude/peon
brew uninstall claude-peon # if installed via brew
```

## License
MIT. You supply your own image/audio; respect their licenses.
