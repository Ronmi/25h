#!/usr/bin/zsh -f

grep docker /etc/group|grep "$(id -un)" > /dev/null 2>&1
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
