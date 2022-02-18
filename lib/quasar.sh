#!/usr/bin/zsh -f

loadlib nvm

# android settings, used in capacitor and cordova
loadlib android

alias qb="quasar build"
alias qba="quasar build -m capacitor -T android"
