#!/usr/bin/env bash
# sf-toolbox bootstrap — First-time installer via curl
#
# Downloads the provisioner repo and hands off to the full installer.
# This script is designed to be piped from curl with zero local dependencies.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/sparkfabrik/archlinux-ansible-provisioner/main/bin/bootstrap.sh)
#
# Override branch (for testing):
#   SF_TOOLBOX_BRANCH=feat/my-branch bash <(curl -fsSL ...)
#
set -euo pipefail

INSTALL_DIR="/opt/archlinux-provisioner"
REPO_URL="https://github.com/sparkfabrik/archlinux-ansible-provisioner.git"
BRANCH="${SF_TOOLBOX_BRANCH:-main}"

# ─── Minimal logging (no external deps) ────────────────────────────────────
info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*"; exit 1; }

# ─── Ensure git is available ────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  info "Installing git..."
  if [[ -f /etc/arch-release ]]; then
    sudo pacman -Sy --noconfirm git
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq git
  else
    error "Cannot install git — unsupported OS"
  fi
fi

# ─── Clone or update ───────────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  info "Updating $INSTALL_DIR..."
  git -C "$INSTALL_DIR" fetch origin
  git -C "$INSTALL_DIR" checkout "$BRANCH"
  git -C "$INSTALL_DIR" pull --ff-only
else
  info "Cloning $REPO_URL → $INSTALL_DIR..."
  sudo mkdir -p "$INSTALL_DIR"
  sudo chown "$USER:$USER" "$INSTALL_DIR"
  git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# ─── Hand off to the real installer ────────────────────────────────────────
exec "$INSTALL_DIR/bin/install.linux"
