#!/usr/bin/zsh -f

id -Gn | grep docker > /dev/null 2>&1
if [[ $? == 0 ]]
then
    alias d=docker
    alias dc=docker-compose
    alias ds=docker-swarm
else
    alias d="sudo docker"
    alias dc="sudo docker-compose"
    alias ds="sudo docker-swarm"
fi
