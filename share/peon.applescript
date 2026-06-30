-- Peon notifier applet.
-- Reads the message text the hook wrote to ~/.claude/peon/.msg, then posts a
-- native macOS notification. Because this runs as its OWN .app bundle, macOS
-- shows the bundle's icon (your image) as the notification icon.
-- The home path is resolved at runtime, so this works for any user.

on run
	set msgPath to (POSIX path of (path to home folder)) & ".claude/peon/.msg"
	try
		set theText to do shell script "/bin/cat " & quoted form of msgPath
	on error
		set theText to "Готов вкалывать"
	end try
	display notification "" with title theText
end run
