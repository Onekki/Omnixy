#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export NIX_CONFIG="$(
  printf '%s\n' "${NIX_CONFIG:-}" "experimental-features = nix-command flakes"
)"

HOST="${HOST:-omnixy}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARDWARE="$ROOT/hosts/$HOST/hardware-configuration.nix"

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo bash scripts/setup.sh"
  exit 1
fi

if [ ! -f "$ROOT/flake.nix" ]; then
  echo "flake.nix not found. Run this from the Omnixy repository root."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git not found; staging git from nixpkgs..."
  GIT_BIN_DIR="$(
    nix shell nixpkgs#git --command bash -c 'dirname "$(command -v git)"' \
      2>/dev/null || true
  )"
  if [ -n "$GIT_BIN_DIR" ] && [ -x "$GIT_BIN_DIR/git" ]; then
    export PATH="$GIT_BIN_DIR:$PATH"
  else
    echo "Could not provision git. Install it first with: nix-shell -p git"
    exit 1
  fi
fi

if [ ! -f "$HARDWARE" ]; then
  echo "Generating hardware config for host '$HOST'..."
  TMP_HW="$(mktemp -d)"
  if nixos-generate-config --dir "$TMP_HW" >/dev/null 2>&1 &&
    [ -f "$TMP_HW/hardware-configuration.nix" ]; then
    cp "$TMP_HW/hardware-configuration.nix" "$HARDWARE"
    rm -rf "$TMP_HW"
  else
    rm -rf "$TMP_HW"
    nixos-generate-config
    cp /etc/nixos/hardware-configuration.nix "$HARDWARE"
  fi
  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$HARDWARE"
  fi
fi

cd "$ROOT"

if [ ! -f "$ROOT/flake.lock" ]; then
  echo "Generating flake.lock..."
  nix flake update
  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$ROOT/flake.lock"
  fi
fi

echo "Building system: nixos-rebuild switch --flake path:$ROOT#$HOST"
nixos-rebuild switch --flake "path:$ROOT#$HOST"
