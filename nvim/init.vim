" ~/.config/nvim/init.vim – managed by github.com/edxleon/dotfiles
" Neovim shares the vim config: same runtime path, same plugins, same ~/.vimrc.
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
