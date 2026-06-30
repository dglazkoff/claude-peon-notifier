// JXA (osascript -l JavaScript) — built into every macOS, no python/jq needed.
// Idempotently merges the Stop / Notification hooks into ~/.claude/settings.json
// without disturbing other settings or duplicating entries.
//
// Usage: osascript -l JavaScript merge-hooks.js <settings.json> <add|remove>

ObjC.import('Foundation');

function readJSON(path) {
  var fm = $.NSFileManager.defaultManager;
  if (!fm.fileExistsAtPath(path)) return {}; // genuinely no file -> start fresh
  // The file exists: a read failure (not UTF-8, permissions) must NOT be treated
  // as "empty", or we'd clobber the user's real settings on write.
  var txt = ObjC.unwrap(
    $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null)
  );
  if (typeof txt !== 'string') {
    throw new Error('Cannot read ' + path + ' as UTF-8; refusing to overwrite it.');
  }
  if (!txt.trim().length) return {};
  return JSON.parse(txt); // throws on malformed JSON — caller surfaces it
}

function isSymlink(path) {
  var fm = $.NSFileManager.defaultManager;
  var attrs = fm.attributesOfItemAtPathError(path, null); // does not follow the link
  if (attrs.isNil()) return false;
  var t = attrs.objectForKey($.NSFileType);
  return !t.isNil() && ObjC.unwrap(t) === 'NSFileTypeSymbolicLink';
}

function writeJSON(path, obj) {
  var out = JSON.stringify(obj, null, 2) + '\n';
  // If settings.json is a symlink (managed dotfiles — stow/chezmoi/etc), write THROUGH
  // it (atomically=false) so we don't replace the link with a regular file and detach
  // it from the dotfiles manager. Otherwise write atomically.
  var atomic = !isSymlink(path);
  var wrote = $.NSString.alloc.initWithUTF8String(out)
    .writeToFileAtomicallyEncodingError(path, atomic, $.NSUTF8StringEncoding, null);
  if (!wrote) throw new Error('Failed to write ' + path);
}

function run(argv) {
  var path = argv[0];
  var mode = argv[1] || 'add';
  var EVENTS = { Stop: 'done', Notification: 'wait' };

  var settings = readJSON(path);
  if (!settings.hooks) settings.hooks = {};

  Object.keys(EVENTS).forEach(function (ev) {
    var cmd = 'bash ~/.claude/peon/notify.sh ' + EVENTS[ev];
    var groups = Array.isArray(settings.hooks[ev]) ? settings.hooks[ev] : [];

    // Drop any existing claude-peon entries for this event (clean re-add / remove).
    groups = groups.filter(function (g) {
      var hooks = (g && g.hooks) || [];
      return !hooks.some(function (h) { return h.command === cmd; });
    });

    if (mode === 'add') {
      groups.push({ hooks: [{ type: 'command', command: cmd }] });
    }

    if (groups.length) settings.hooks[ev] = groups;
    else delete settings.hooks[ev];
  });

  if (settings.hooks && Object.keys(settings.hooks).length === 0) delete settings.hooks;

  writeJSON(path, settings);
  return 'ok';
}
