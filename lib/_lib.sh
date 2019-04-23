#!/bin/zsh -f

function test_func {
    whence -w "$1" | cut -d : -f 2 | grep function > /dev/null 2>&1
}
