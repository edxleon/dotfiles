# Dotfiles

zsh · tmux · vim · starship – fast, few moving parts, one Gruvbox look.
**macOS first** (Homebrew), Debian/Ubuntu/WSL second (apt).
Sibling of [dotfiles-windows](https://github.com/edxleon/dotfiles-windows): same tools, aliases and key bindings.

## Install

```sh
git clone https://github.com/edxleon/dotfiles.git ~/dotfiles   # any path works
cd ~/dotfiles
./install.sh
exec zsh
```

Options: `--no-packages` (links + plugins only), `--no-plugins`, `--no-chsh`.

- **macOS:** packages from `./Brewfile` (Homebrew must already be installed).
- **Linux:** packages via apt; starship falls back to its release binary, verified against its sha256.
- Configs are **symlinks** into this repo, so `git pull` takes effect on the next shell start.
- Existing files are moved to `~/.dotfiles-backup/<timestamp>/`, never deleted. Rerunning is safe.

### After installing (macOS Terminal)

Settings → Profiles → your profile:
- **Text → Font:** *JetBrainsMono Nerd Font* (icons in prompt and `ls`).
- **Keyboard → "Use Option as Meta key"** (needed for the Alt shortcuts below).

## What goes where

| Repo | Linked to |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `vim/vimrc` | `~/.vimrc` |
| `starship/starship.toml` | `~/.config/starship.toml` |

Untracked, machine-specific overrides: `~/.zshrc.local`, `~/.vimrc.local`, `~/.config/tmux/local.conf`.

## Design

- **Built-ins before plugins.** No zsh framework, no tmux plugins, 4 vim plugins.
  Vim 9.1 brings comments (`gc`), auto-clearing search highlight and a Gruvbox-like colour scheme (`retrobox`).
- **Fast startup.** Cached completion (full check once a day), one process per tool init,
  starship with only the modules in use and a 300 ms command timeout.
- **AI-safe.** When `CLAUDECODE` is set (Claude Code), `.zshrc` stops after PATH/EDITOR,
  so agents get a plain shell without `mv -i` or `cat=bat` surprises.

## Tools

| Tool | Purpose |
|---|---|
| [starship](https://starship.rs) | prompt |
| [fzf](https://github.com/junegunn/fzf) | `Ctrl+T` files · `Ctrl+R` history · `Alt+C` cd |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z <part-of-path>` |
| [eza](https://github.com/eza-community/eza) · [bat](https://github.com/sharkdp/bat) | `ls` with icons + git · `cat` with highlighting |
| [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) | fast grep · fast find |
| zsh-autosuggestions · zsh-syntax-highlighting | suggestions as you type · command colouring |

## Shell

| Key | Action |
|---|---|
| `↑` / `↓` | history search by what you've typed |
| `Tab` | completion menu |
| `→` / `Ctrl+F` | accept suggestion / accept one word |

| Command | Does |
|---|---|
| `ll`, `lt` | long list with git status / tree (3 levels) |
| `..`, `...`, `....` | go up |
| `mkcd dir`, `up 3` | create + enter / go up n levels |
| `gs`, `glog`, `gpull`, `gpush`, `gco`, `gcb`, `g` | git |
| `dps`, `dex`, `dlogs`, `dimg`, `dprune` | docker (if installed) |
| `ports` | listening ports |
| `update` | `brew update && upgrade` / `apt update && upgrade` |

`mv`, `cp` and `ln` ask before overwriting.

## tmux

Prefix is **`Ctrl+Space`**. No plugins.

| Key | Action |
|---|---|
| `prefix \|` / `prefix -` | split side by side / stacked (in the current directory) |
| `Alt+h/j/k/l` | move between panes – and vim splits (`prefix h/j/k/l` also works) |
| `Alt+1…9` | select window |
| `prefix Enter` | copy mode: `v` select, `y` copy to system clipboard |
| `prefix m` | toggle mouse |
| `prefix r` / `prefix e` | reload config / edit local.conf |

## vim

Leader is **`,`**. Plugins: fzf.vim, vim-tmux-navigator, fugitive (via vim-plug).

| Key | Action |
|---|---|
| `,f` / `,b` / `,r` | fzf: files / buffers / ripgrep |
| `,e` | file tree (built-in netrw) |
| `,w` | save |
| `gcc` / `gc` + motion | toggle comment |
| `:Git` | fugitive |
| `,ev` `,et` `,ez` | edit vimrc / tmux.conf / zshrc |

## History

The 2017–2020 version (fish, oh-my-zsh, i3, YouCompleteMe) is in the git history.
2026 rewrite: fish → zsh, oh-my-zsh → two plain plugins, 17 vim plugins → 4 plus built-ins,
5 tmux plugins → none, Tokyo Night → Gruvbox, neovim dropped (Vim 9.1 ships with macOS and Debian).
