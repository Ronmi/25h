25h
===

my zsh configuration (mainly with fizsh)

## Usage

```sh
# clone it
git clone https://github.com/Ronmi/25h "${HOME}/.zsh.d"

# update fizsh config
echo 'source "${HOME}/.zsh.d/zshrc"' >> "${HOME}/.fizsh/.zshrc"
# or with zsh
ln -sf "${HOME}/.zsh.d/zshrc" "${HOME}/.zshrc"

# done, open a new terminal or re-login to enable
```

In addition, for Emacs and other programs using bash by default

```sh
echo 'source "${HOME}/.zsh.d/bash_profile"' >> "${HOME}/.bashrc"
```

## Highlights

- S95_workhere: experimental project workspace support
- S90_go: golang with multiple golang version support
- S90_nvm/phpbrew/rust/composer: auto initializing
- S01_wsl/S90/docker: experimental wsl and docker in wsl support
- emacs support (by switching back to bash)
