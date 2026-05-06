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
info()  { printf '\033[1m\033[93m[ \033[92m•\033[93m ] \033[4m%s\033[0m\n' "$*"; }
error() { printf '\033[1m\033[31m[FAIL] %s\033[0m\n' "$*"; exit 1; }

# ─── Banner ─────────────────────────────────────────────────────────────────
printf '\033[H\033[2J\033[3J'

cat <<'EOF'

 ░▒▓███████▓▒░▒▓████████▓▒░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░      ░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░
 ░▒▓█▓▒░      ░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
 ░▒▓█▓▒░      ░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
  ░▒▓██████▓▒░░▒▓██████▓▒░    ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░
        ░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
        ░▒▓█▓▒░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
 ░▒▓███████▓▒░░▒▓█▓▒░         ░▒▓█▓▒░   ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓████████▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░

  SparkFabrik Linux Toolbox — First-time setup
  ─────────────────────────────────────────────

EOF

# ─── Explain what this script does ──────────────────────────────────────────
printf '  This script will:\n'
printf '\n'
printf '    1. Install git (if not already present)\n'
printf '    2. Clone the provisioner repository into:\n'
printf '       \033[1m%s\033[0m\n' "$INSTALL_DIR"
printf '    3. Run the sf-toolbox Ansible installer\n'
printf '\n'
printf '  Repository: %s\n' "$REPO_URL"
printf '  Branch:     \033[1m%s\033[0m\n' "$BRANCH"
printf '\n'

# ─── Confirmation ──────────────────────────────────────────────────────────
if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
  printf '  Continue? [Y/n] '
  read -r answer
  case "${answer:-Y}" in
    [Yy]*|"") ;;
    *) printf '\n  Aborted.\n'; exit 0 ;;
  esac
  printf '\n'
fi

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
  info "Cloning repository → $INSTALL_DIR..."
  sudo mkdir -p "$INSTALL_DIR"
  sudo chown "$USER:$USER" "$INSTALL_DIR"
  git clone -b "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# ─── Hand off to the real installer ────────────────────────────────────────
info "Launching sf-toolbox installer..."
exec "$INSTALL_DIR/bin/install.linux"
