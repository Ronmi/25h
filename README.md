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
  * separated command history
  * various tools like command aliases and helper functions
  * write your own and put it in `~/.zsh.d/lib/local/my-func.sh`, load with `loadlib local/my-func` in `{workspace_dir}/.rmi-work/config.zsh`
  * overwrites `cd` command, execute cd without args will go back to project root
- `S90_*`: various devtools support
