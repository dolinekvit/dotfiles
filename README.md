# dotfiles

Managed with [GNU stow](https://www.gnu.org/software/stow/). Each top-level
folder is a "package". Its inner layout mirrors `$HOME`, and stow creates the
symlinks for you.

```
dotfiles/
├── ghostty/
│   └── .config/ghostty/config   ->  ~/.config/ghostty/config
└── tmux/
    └── .tmux.conf               ->  ~/.tmux.conf
```

## Setup

Put this repo in your home dir (the path matters — stow links relative to the
parent of the repo):

```
git clone <your-repo> ~/dotfiles
cd ~/dotfiles
```

Install stow:

```
brew install stow        # macOS
sudo apt install stow     # Debian/Ubuntu
sudo pacman -S stow       # Arch
```

## Use

From inside `~/dotfiles`:

```
stow ghostty      # link the ghostty config into place
stow tmux         # link .tmux.conf into place
```

To preview without touching anything:

```
stow -n -v ghostty
```

To remove the symlinks:

```
stow -D ghostty
```

To relink after moving files around:

```
stow -R ghostty
```

## Adding a new tool later

1. Make a folder named after the tool.
2. Inside it, recreate the path the config lives at, relative to `$HOME`.
   e.g. for `~/.config/nvim/init.lua`  ->  `dotfiles/nvim/.config/nvim/init.lua`
3. `stow nvim`

One rule to remember: the structure inside a package is exactly where the file
should land in your home directory. Nothing else to configure.

## Note: stow won't overwrite existing files

If `~/.tmux.conf` already exists as a real file, `stow tmux` errors out instead
of clobbering it. Move the old one aside first (`mv ~/.tmux.conf ~/.tmux.conf.bak`),
then stow.
