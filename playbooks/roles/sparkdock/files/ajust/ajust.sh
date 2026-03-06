#!/usr/bin/env bash

# check if just is installed, otherwise install it with pacman.
if ! command -v just &> /dev/null
then
    echo "just could not be found, installing it with pacman"
    sudo pacman -S --noconfirm just
fi

just --justfile "${HOME}/.local/spark/ajust/justfile" "${@}"
