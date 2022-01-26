#!/usr/bin/zsh -f

id -Gn | grep docker > /dev/null 2>&1
if [[ $? == 0 ]]
then
    function d {
        docker "$@"
    }
    alias dc=docker-compose
    alias ds=docker-swarm
else
    function d {
        sudo docker "$@"
    }
    alias dc="sudo docker-compose"
    alias ds="sudo docker-swarm"
fi
