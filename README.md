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
lh -sf "${HOME}/.zsh.d/bash_profile" "${HOME}/.profie"
```

## Highlights

- `S95_workhere` and `lib/*`: project workspace support
- `S90_*`: various devtools support
