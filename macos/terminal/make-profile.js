// Generates macos/terminal/Gruvbox.terminal – a Terminal.app profile matching tmux, starship and vim.
// Run: osascript -l JavaScript macos/terminal/make-profile.js   (rewrites Gruvbox.terminal next to this file)
// Colors: gruvbox dark (github.com/morhetz/gruvbox palette). Font: JetBrainsMono Nerd Font Mono.
ObjC.import('AppKit');

const BG_OPACITY = 0.90;     // background alpha: 1.0 opaque, lower = more see-through
const BG_BLUR = 0.5;         // blur of what shows through (0–1)
const LINE_SPACING = 0.95;   // Terminal → Profiles → Text → Line spacing (default 1.0); tuned by eye on the 5K display
const PROFILE_VERSION = 5;    // bump on every change – install.sh re-imports when it differs

function run(argv) {
  const here = $.NSString.stringWithString($.NSProcessInfo.processInfo.environment.objectForKey('PWD').js + '/macos/terminal').js;
  const out = (argv[0] || here) + '/Gruvbox.terminal';

  const hex = h => { const n = parseInt(h.slice(1), 16); return [(n >> 16 & 255) / 255, (n >> 8 & 255) / 255, (n & 255) / 255]; };
  const archive = obj => $.NSKeyedArchiver.archivedDataWithRootObjectRequiringSecureCodingError(obj, false, null);
  const color = (h, a = 1) => { const [r, g, b] = hex(h); return archive($.NSColor.colorWithSRGBRedGreenBlueAlpha(r, g, b, a)); };

  const palette = {
    ANSIBlackColor: '#282828',   ANSIBrightBlackColor: '#928374',
    ANSIRedColor: '#cc241d',     ANSIBrightRedColor: '#fb4934',
    ANSIGreenColor: '#98971a',   ANSIBrightGreenColor: '#b8bb26',
    ANSIYellowColor: '#d79921',  ANSIBrightYellowColor: '#fabd2f',
    ANSIBlueColor: '#458588',    ANSIBrightBlueColor: '#83a598',
    ANSIMagentaColor: '#b16286', ANSIBrightMagentaColor: '#d3869b',
    ANSICyanColor: '#689d6a',    ANSIBrightCyanColor: '#8ec07c',
    ANSIWhiteColor: '#a89984',   ANSIBrightWhiteColor: '#ebdbb2',
    BackgroundColor: '#282828',
    TextColor: '#ebdbb2',
    TextBoldColor: '#fbf1c7',
    CursorColor: '#ebdbb2',
    SelectionColor: '#504945',
  };

  const font = $.NSFont.fontWithNameSize('JetBrainsMonoNFM-Regular', 14);
  if (font.isNil()) throw new Error('JetBrainsMono Nerd Font Mono not available – install the font first');

  const d = $.NSMutableDictionary.dictionary;
  Object.entries(palette).forEach(([k, v]) => d.setObjectForKey(color(v), k));
  d.setObjectForKey(color(palette.BackgroundColor, BG_OPACITY), 'BackgroundColor');   // slightly transparent
  d.setObjectForKey($.NSNumber.numberWithDouble(BG_BLUR), 'BackgroundBlur');
  d.setObjectForKey(archive(font), 'Font');
  d.setObjectForKey('Gruvbox', 'name');
  d.setObjectForKey($.NSNumber.numberWithInt(PROFILE_VERSION), 'dotfilesProfileVersion');
  d.setObjectForKey('Window Settings', 'type');
  d.setObjectForKey($.NSNumber.numberWithDouble(2.07), 'ProfileCurrentVersion');
  d.setObjectForKey($.NSNumber.numberWithBool(true), 'FontAntialias');
  d.setObjectForKey($.NSNumber.numberWithBool(true), 'useOptionAsMetaKey');   // Alt shortcuts in tmux/vim/zsh
  d.setObjectForKey($.NSNumber.numberWithBool(false), 'UseBrightBold');       // bold stays bold, not recoloured
  d.setObjectForKey($.NSNumber.numberWithBool(false), 'Bell');                // no audible bell
  d.setObjectForKey($.NSNumber.numberWithBool(true), 'VisualBellOnlyWhenMuted');
  // Line spacing: Terminal.app adds leading above each line that powerline caps don't fill,
  // leaving a step at the top of the tmux pills. < 1.0 trims it.
  d.setObjectForKey($.NSNumber.numberWithDouble(LINE_SPACING), 'FontHeightSpacing');
  // Home/End go to the shell (line start/end) instead of scrolling the window – Windows habit
  const keys = $.NSMutableDictionary.dictionary;
  keys.setObjectForKey('\u001b[H', 'F729');   // Home
  keys.setObjectForKey('\u001b[F', 'F72B');   // End
  d.setObjectForKey(keys, 'keyMapBoundKeys');
  d.setObjectForKey($.NSNumber.numberWithInt(120), 'columnCount');
  d.setObjectForKey($.NSNumber.numberWithInt(36), 'rowCount');

  if (!d.writeToFileAtomically(out, true)) throw new Error('could not write ' + out);
  return 'written: ' + out;
}
