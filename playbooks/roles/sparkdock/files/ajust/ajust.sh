#!/usr/bin/env bash

# check if just is installed, otherwise install it with pacman.
if ! command -v just &> /dev/null; then
  echo "just could not be found!"
  echo "Please install just using the provisioner or your package manager and try again."
  exit 1
fi

just --justfile "${HOME}/.local/spark/ajust/justfile" "${@}"
