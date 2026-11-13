#!/usr/bin/env bash
# Run only inside the disposable Arch CI container.
set -euo pipefail
case "${LEGACY_PACKAGE:?legacy package required}" in
  chatgpt-desktop|chatgpt|openai-codex-desktop) ;;
  *) exit 1 ;;
esac
fixture=$(mktemp -d)
mkdir -p "${fixture}/usr/bin" /home/desktop-user/.config/ChatGPT
printf 'user data must survive migration\n' > /home/desktop-user/.config/ChatGPT/migration-sentinel
printf '#!/bin/sh\nexit 0\n' > "${fixture}/usr/bin/chatgpt"
chmod 755 "${fixture}/usr/bin/chatgpt"
cat > "${fixture}/.PKGINFO" <<EOF
pkgname = ${LEGACY_PACKAGE}
pkgver = 1-1
pkgdesc = Legacy desktop migration fixture
arch = x86_64
provides = chatgpt
conflict = chatgpt
EOF
bsdtar --uid 0 --gid 0 --zstd -cf /tmp/legacy-desktop.pkg.tar.zst -C "${fixture}" .PKGINFO usr
pacman -U --noconfirm --ask=4 /tmp/legacy-desktop.pkg.tar.zst
