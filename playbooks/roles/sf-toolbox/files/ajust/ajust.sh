#!/usr/bin/env bash

# check if just is installed, otherwise install it.
if ! command -v just &> /dev/null; then
  if command -v pacman &> /dev/null; then
    echo "just could not be found, installing it with pacman"
    sudo pacman -S --noconfirm just
  elif command -v brew &> /dev/null; then
    echo "just could not be found, installing it with brew"
    brew install just
  else
    echo "Error: just is not installed and no supported package manager found."
    echo "Install just manually: https://just.systems/man/en/installation.html"
    exit 1
  fi
fi

just --justfile "${HOME}/.local/spark/ajust/justfile" "${@}"
