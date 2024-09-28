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

You might want to add `source ~/.zsh.d/bash_profile` in `~/.zshenv` if you are using Emacs GUI.

## Highlights

- S95_workhere: experimental project workspace support
- S90_*: various devtools support
- S01_wsl/S90_docker: experimental wsl and docker in wsl support
