#!/usr/bin/env bash
# Dotfiles installer – macOS (Homebrew) first, Debian/Ubuntu/WSL (apt) second.
# Idempotent – safe to run again after `git pull`.
#
#   ./install.sh                 packages + links + plugins + default shell
#   ./install.sh --no-packages   only links + plugins (no brew/sudo)
#   ./install.sh --no-plugins    skip vim-plug
#   ./install.sh --no-chsh       don't change the login shell
#   ./install.sh --no-terminal   macOS: leave Terminal.app profile/font alone
#
# Existing files are never deleted: they're moved to ~/.dotfiles-backup/<timestamp>/.
# Nothing is piped into a shell: macOS packages come from ./Brewfile, Linux packages from apt;
# starship on Linux (if apt has none) comes from its GitHub release, checked against its sha256.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"          # see tools installed here by earlier runs
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DO_PACKAGES=1 DO_PLUGINS=1 DO_CHSH=1 DO_TERMINAL=1

for arg in "$@"; do
  case "$arg" in
    --no-packages) DO_PACKAGES=0 ;;
    --no-plugins)  DO_PLUGINS=0 ;;
    --no-chsh)     DO_CHSH=0 ;;
    --no-terminal) DO_TERMINAL=0 ;;
    -h|--help)     sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
ok()   { printf '    \033[32m[ok]\033[0m %s\n' "$1"; }
skip() { printf '    \033[90m[--]\033[0m %s\n' "$1"; }
warn() { printf '    \033[33m[!!]\033[0m %s\n' "$1"; }

# ── Packages ──────────────────────────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then SUDO=""; elif command -v sudo >/dev/null; then SUDO="sudo"; else SUDO="none"; fi

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed"; }
available() { [ -n "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{ if ($2 != "(none)") print $2 }')" ]; }

install_starship_release() {
  local arch target url tmp
  [ "$(uname -s)" = "Linux" ] || { warn "starship: not Linux – install it with your package manager"; return 0; }
  arch="$(uname -m)"
  case "$arch" in
    x86_64)        target="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) target="aarch64-unknown-linux-musl" ;;
    *) warn "starship: no release for $arch – install it manually"; return 0 ;;
  esac
  url="https://github.com/starship/starship/releases/latest/download/starship-$target.tar.gz"
  tmp="$(mktemp -d)"
  curl -fsSLo "$tmp/starship.tar.gz" "$url"
  curl -fsSLo "$tmp/starship.tar.gz.sha256" "$url.sha256"
  if [ "$(sha256sum "$tmp/starship.tar.gz" | cut -d' ' -f1)" != "$(tr -d '[:space:]' < "$tmp/starship.tar.gz.sha256")" ]; then
    warn "starship: checksum mismatch – not installed"; rm -rf "$tmp"; return 0
  fi
  mkdir -p "$HOME/.local/bin"
  tar -xzf "$tmp/starship.tar.gz" -C "$HOME/.local/bin" starship
  rm -rf "$tmp"
  ok "starship → ~/.local/bin (release, sha256 verified)"
}

add_eza_repo() {
  # eza's own signed apt repo, for distros that don't ship eza (Debian 12, Ubuntu 22.04)
  [ -f /etc/apt/sources.list.d/gierens.list ] && return 0
  $SUDO apt-get install -y -qq gpg >/dev/null
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | $SUDO gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
  $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  $SUDO apt-get update -qq
  ok "eza apt repo added"
}

OS="$(uname -s)"

if [ "$DO_PACKAGES" = 1 ] && [ "$OS" = "Darwin" ]; then
  step "Packages (Homebrew)"
  if ! command -v brew >/dev/null; then
    warn "Homebrew missing – install it from https://brew.sh, then rerun (or use --no-packages)"
  elif brew bundle check --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
    skip "everything in Brewfile present"
  else
    brew bundle install --file="$DOTFILES/Brewfile"
    ok "Brewfile installed"
  fi
elif [ "$DO_PACKAGES" = 1 ]; then
  step "Packages (apt)"
  if ! command -v apt-get >/dev/null; then
    warn "no apt-get – package install supports Debian/Ubuntu only. Install manually:"
    warn "zsh tmux vim git fzf zoxide bat eza ripgrep fd starship zsh-autosuggestions zsh-syntax-highlighting"
  elif [ "$SUDO" = "none" ]; then
    warn "no sudo – skipping packages (rerun as root or with --no-packages)"
  else
    $SUDO apt-get update -qq
    for p in curl ca-certificates; do installed "$p" || $SUDO apt-get install -y -qq "$p" >/dev/null; done
    wanted=(zsh tmux vim git curl ca-certificates fzf zoxide bat ripgrep fd-find
            zsh-autosuggestions zsh-syntax-highlighting)
    available eza || add_eza_repo
    wanted+=(eza)
    available starship && wanted+=(starship)

    missing=()
    for p in "${wanted[@]}"; do installed "$p" || missing+=("$p"); done
    if [ ${#missing[@]} -gt 0 ]; then
      $SUDO apt-get install -y -qq "${missing[@]}" >/dev/null
      ok "installed: ${missing[*]}"
    else
      skip "all packages present"
    fi
  fi
  if command -v starship >/dev/null; then skip "starship present"; else install_starship_release; fi
fi

# Debian ships bat/fd as batcat/fdfind – provide the usual names for scripts and fzf.vim
mkdir -p "$HOME/.local/bin"
for pair in batcat:bat fdfind:fd; do
  src="${pair%%:*}" dst="${pair##*:}"
  if command -v "$src" >/dev/null && ! command -v "$dst" >/dev/null && [ ! -e "$HOME/.local/bin/$dst" ]; then
    ln -s "$(command -v "$src")" "$HOME/.local/bin/$dst"
    ok "~/.local/bin/$dst → $src"
  fi
done

# ── Links ─────────────────────────────────────────────────────────────────────
step "Config links"
backup() {
  mkdir -p "$BACKUP/$(dirname "${1#"$HOME"/}")"
  mv "$1" "$BACKUP/${1#"$HOME"/}"
  ok "backed up ${1/#$HOME/~} → ${BACKUP/#$HOME/~}/"
}
link() {
  local src="$DOTFILES/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then skip "${dst/#$HOME/~}"; return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then backup "$dst"; fi
  ln -s "$src" "$dst"
  ok "${dst/#$HOME/~} → $1"
}

link zsh/zshrc              "$HOME/.zshrc"
link vim/vimrc              "$HOME/.vimrc"
link tmux/tmux.conf         "$HOME/.config/tmux/tmux.conf"
link starship/starship.toml "$HOME/.config/starship.toml"

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf – move an old one out of the way
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then backup "$HOME/.tmux.conf"; fi

# ── macOS Terminal.app: Nerd Font active + Gruvbox profile as default ─────────
font_visible() {
  [ "$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSFont.fontWithNameSize("JetBrainsMonoNFM-Regular", 13).isNil() ? "no" : "yes"' 2>/dev/null)" = "yes" ]
}
if [ "$OS" = "Darwin" ] && [ "$DO_TERMINAL" = 1 ]; then
  step "Terminal.app"
  if font_visible; then
    skip "JetBrainsMono Nerd Font active"
  elif ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont*.ttf >/dev/null 2>&1; then
    # macOS doesn't always pick up fonts dropped into ~/Library/Fonts; fontd rescans on restart
    killall fontd 2>/dev/null || true
    sleep 3
    if font_visible; then ok "Nerd Font activated (fontd rescan)"; else warn "Nerd Font files present but not active – open them once in Font Book"; fi
  else
    warn "JetBrainsMono Nerd Font missing – brew install --cask font-jetbrains-mono-nerd-font"
  fi

  # Profile: import when missing or when its version differs from the repo's.
  # Terminal names a re-imported profile "Gruvbox N", so the new one replaces the old one afterwards.
  profile="$DOTFILES/macos/terminal/Gruvbox.terminal"
  want="$(plutil -extract dotfilesProfileVersion raw "$profile" 2>/dev/null)"
  have="$(defaults export com.apple.Terminal - 2>/dev/null | plutil -extract "Window Settings.Gruvbox.dotfilesProfileVersion" raw - 2>/dev/null || true)"
  if [ -n "$have" ] && [ "$have" = "$want" ]; then
    skip "profile Gruvbox up to date (v$have)"
  else
    open "$profile"                                    # Terminal's own import; opens a preview window
    sleep 2
    newest="$(osascript -e 'tell application "Terminal" to get name of every settings set' \
              | tr ',' '\n' | sed 's/^ *//' | grep -E '^Gruvbox( [0-9]+)?$' | sort -t' ' -k2 -n | tail -1)"
    if [ -n "$newest" ] && [ "$newest" != "Gruvbox" ]; then
      osascript >/dev/null <<APPLESCRIPT
tell application "Terminal"
  set g to settings set "$newest"
  set default settings to g
  set startup settings to g
  repeat with w in windows
    repeat with t in tabs of w
      if name of current settings of t is "Gruvbox" then set current settings of t to g
    end repeat
  end repeat
  delete settings set "Gruvbox"
  set name of g to "Gruvbox"
end tell
APPLESCRIPT
    fi
    ok "profile Gruvbox imported (v$want)"
  fi
  if [ "$(osascript -e 'tell application "Terminal" to name of default settings' 2>/dev/null)" = "Gruvbox" ]; then
    skip "Gruvbox is the default profile"
  else
    osascript -e 'tell application "Terminal" to set default settings to settings set "Gruvbox"' \
              -e 'tell application "Terminal" to set startup settings to settings set "Gruvbox"' >/dev/null
    ok "Gruvbox set as default + startup profile"
  fi
fi

# ── Plugins ───────────────────────────────────────────────────────────────────
if [ "$DO_PLUGINS" = 1 ]; then
  step "Plugins"
  if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
    skip "vim-plug present"
  else
    curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed"
  fi
  if command -v vim >/dev/null; then
    # PlugClean! removes plugins no longer listed in the vimrc
    vim -Es -u "$HOME/.vimrc" +'PlugClean!' +PlugInstall +qall </dev/null >/dev/null 2>&1 || true
    ok "vim plugins installed/updated/cleaned"
  fi
  # tmux needs no plugins; a leftover tpm dir from older versions is unused
  if [ -d "$HOME/.config/tmux/plugins" ]; then warn "~/.config/tmux/plugins is unused now – remove it if you like"; fi
fi

# ── Login shell ───────────────────────────────────────────────────────────────
if [ "$DO_CHSH" = 1 ] && command -v zsh >/dev/null; then
  step "Login shell"
  zsh_path="$(command -v zsh)"
  if [ "$OS" = "Darwin" ]; then
    current_shell="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
  else
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  fi
  if [ "$current_shell" = "$zsh_path" ]; then
    skip "zsh is already the login shell"
  elif chsh -s "$zsh_path"; then
    ok "login shell → zsh (takes effect at next login)"
  else
    warn "chsh failed – run: chsh -s $zsh_path"
  fi
fi

printf '\n\033[32mDone.\033[0m Start a new shell: exec zsh\n'
[ "$(uname -s)" = "Darwin" ] || printf '\033[90mTerminal font: a Nerd Font (e.g. JetBrainsMono Nerd Font) for prompt icons.\033[0m\n'
