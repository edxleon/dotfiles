# Dotfiles (Linux)

zsh · tmux · vim/neovim · starship – one Gruvbox look across shell, prompt, multiplexer and editor.
Linux counterpart of [dotfiles-windows](https://github.com/edxleon/dotfiles-windows): same tools, aliases and key bindings.

Target: Debian/Ubuntu, including WSL. The configs work on any Linux (and macOS);
only the package step needs `apt`.

## Install

```sh
git clone https://github.com/edxleon/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

Options: `--no-packages` (links + plugins only, no sudo), `--no-plugins`, `--no-chsh`.

`install.sh` is idempotent. Configs are **symlinks** into this repo, so `git pull` applies
changes on the next shell start. Existing files are moved to `~/.dotfiles-backup/<timestamp>/`,
never deleted. Nothing is piped into a shell: packages come from apt; if apt has no starship,
the release binary is downloaded and verified against its sha256.

For prompt icons, set your terminal font to a Nerd Font (e.g. JetBrainsMono Nerd Font).

## What goes where

| Repo | Linked to |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `vim/vimrc` | `~/.vimrc` |
| `nvim/init.vim` | `~/.config/nvim/init.vim` (loads `~/.vimrc`) |
| `starship/starship.toml` | `~/.config/starship.toml` |

Machine-specific, untracked overrides: `~/.zshrc.local`, `~/.config/tmux/local.conf`.

## Tools

| Tool | Purpose |
|---|---|
| [starship](https://starship.rs) | prompt (Gruvbox) |
| [fzf](https://github.com/junegunn/fzf) | `Ctrl+T` files, `Ctrl+R` history, `Alt+C` cd |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z <part-of-path>` |
| [eza](https://github.com/eza-community/eza) | `ls` with icons and git status |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd) | fast grep / find |
| zsh-autosuggestions, zsh-syntax-highlighting | fish-like shell |

## Shell

| Key | Action |
|---|---|
| `↑` / `↓` | history search by what you've typed |
| `Tab` | completion menu |
| `Ctrl+F`, `Ctrl+←/→` | word jumps |

| Command | Does |
|---|---|
| `ll`, `lt` | long list with git status / tree (3 levels) |
| `..`, `...`, `....` | go up |
| `mkcd dir`, `up 3` | create + enter / go up n levels |
| `gs`, `glog`, `gpull`, `gpush`, `gco`, `gcb`, `g` | git |
| `dps`, `dex`, `dlogs`, `dimg`, `dprune` | docker (if installed) |
| `ports` | listening ports (`ss -tulpn`) |
| `update` | `apt update && apt upgrade` |

`mv`, `cp` and `ln` ask before overwriting.

## tmux

Prefix is **`Ctrl+Space`**.

| Key | Action |
|---|---|
| `prefix v` / `prefix h` | split side by side / stacked |
| `Alt+h/j/k/l` | move between panes – and vim splits |
| `Alt+1…9` | select window |
| `Alt+Shift+W/S` | swap pane up/down |
| `prefix Enter` | copy mode (`v` select, `y` yank) |
| `prefix m` | toggle mouse |
| `prefix r` / `prefix e` | reload config / edit local.conf |

Plugins: sensible, yank, open, resurrect + continuum (sessions survive reboots).

## vim / neovim

Leader is **`,`**.

| Key | Action |
|---|---|
| `,n` | file tree |
| `,f` / `,b` / `,r` | fzf: files / buffers / ripgrep |
| `,w` | save |
| `,F` | fix file (ALE) |
| `[e` / `]e` | previous / next lint error |
| `,cc` / `,cu` | comment / uncomment |
| `Ctrl+a/s/d` | resize split |
| `,ev` `,et` `,ez` | edit vimrc / tmux.conf / zshrc |

Plugins: nerdtree, fzf.vim, vim-tmux-navigator, easymotion, fugitive, gitgutter, airline,
gruvbox, surround, nerdcommenter, auto-pairs, polyglot, ALE (lint/fix/LSP completion –
install linters like `ruff` or `shellcheck` as needed).

## History

The 2017–2020 version (fish, oh-my-zsh, i3, YouCompleteMe) is in the git history.
This rewrite replaced fish with zsh, oh-my-zsh with two plain plugins,
syntastic/YouCompleteMe with ALE, and Tokyo Night with Gruvbox.
