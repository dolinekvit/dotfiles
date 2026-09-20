# dotfiles

My personal dotfiles, tailored to my daily use.

Managed with [GNU stow](https://www.gnu.org/software/stow/).

```
dotfiles/
├── ghostty/
│   └── .config/ghostty/config     ->  ~/.config/ghostty/config
├── lazygit/
│   └── .config/lazygit/config.yml ->  ~/.config/lazygit/config.yml
├── lazydocker/
│   └── .config/lazydocker/config.yml ->  ~/.config/lazydocker/config.yml
├── nvim/
│   └── .config/nvim/              ->  ~/.config/nvim/
├── starship/
│   └── .config/starship.toml      ->  ~/.config/starship.toml
└── tmux/
    └── .config/tmux/tmux.conf     ->  ~/.config/tmux/tmux.conf
```

Every package mirrors the tree it should produce under `$HOME`, so stow is
always run with `$HOME` as the target:

```
stow -t ~ tmux          # link one package
stow -t ~ */            # link them all
stow -t ~ -D tmux       # unlink
```
