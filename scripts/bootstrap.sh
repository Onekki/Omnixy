#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export NIX_CONFIG="$(
  printf '%s\n' "${NIX_CONFIG:-}" "experimental-features = nix-command flakes"
)"

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

HOST="${HOST:-omnixy}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARDWARE="$ROOT/hosts/$HOST/hardware-configuration.nix"

if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo: sudo bash scripts/bootstrap.sh"
  exit 1
fi

if [ ! -f "$ROOT/flake.nix" ]; then
  echo "flake.nix not found. Run this from the Omnixy repository root."
  exit 1
fi

OMNIXY_CONFIG="$ROOT/config/omnixy.nix"
if [ ! -f "$OMNIXY_CONFIG" ]; then
  echo "Generating config/omnixy.nix..."
  mkdir -p "$(dirname "$OMNIXY_CONFIG")"
  cat > "$OMNIXY_CONFIG" <<'EOF'
{
  system = {
    hostname = "@HOSTNAME@";
    timezone = "@TIMEZONE@";
    locale = "@LOCALE@";
    networkManager = true;
    mirror = "@MIRROR@";
  };
  user = {
    name = "@USERNAME@";
    fullName = "@FULLNAME@";
    hashedPassword = null;
    extraGroups = [ ];
  };
  enabledModules = [ "core" "denial" "rime" ];
  settings = {
    core = { };
    denial = {
      displayManager = "sddm";
      autologin = false;
    };
    rime = {
      overwrite = false;
    };
  };
}
EOF

  DEFAULT_HOSTNAME="${OMNIXY_HOSTNAME:-$(hostnamectl --static 2>/dev/null || true)}"
  [ -n "$DEFAULT_HOSTNAME" ] || DEFAULT_HOSTNAME="omnixy"
  DEFAULT_USER="${OMNIXY_USER:-${SUDO_USER:-user}}"
  DEFAULT_TIMEZONE="${OMNIXY_TIMEZONE:-$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')}"
  [ -n "$DEFAULT_TIMEZONE" ] || DEFAULT_TIMEZONE="UTC"
  DEFAULT_LOCALE="${OMNIXY_LOCALE:-en_US.UTF-8}"
  DEFAULT_MIRROR="global"
  case "$DEFAULT_TIMEZONE" in
    Asia/Shanghai|Asia/Hong_Kong|Asia/Taipei|Asia/Macau)
      DEFAULT_MIRROR="china"
      ;;
  esac
  DEFAULT_MIRROR="${OMNIXY_MIRROR:-$DEFAULT_MIRROR}"

  if [ -t 0 ]; then
    read -r -p "Hostname [$DEFAULT_HOSTNAME]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_HOSTNAME="$INPUT"
    read -r -p "Username [$DEFAULT_USER]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_USER="$INPUT"
    read -r -p "Timezone [$DEFAULT_TIMEZONE]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_TIMEZONE="$INPUT"
    read -r -p "Mirror (china/global) [$DEFAULT_MIRROR]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_MIRROR="$INPUT"
  fi

  sed -i \
    -e "s|@HOSTNAME@|$DEFAULT_HOSTNAME|g" \
    -e "s|@USERNAME@|$DEFAULT_USER|g" \
    -e "s|@FULLNAME@|$DEFAULT_USER|g" \
    -e "s|@TIMEZONE@|$DEFAULT_TIMEZONE|g" \
    -e "s|@LOCALE@|$DEFAULT_LOCALE|g" \
    -e "s|@MIRROR@|$DEFAULT_MIRROR|g" \
    "$OMNIXY_CONFIG"

  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$OMNIXY_CONFIG"
  fi
fi

if [ -f "$HARDWARE" ]; then
  echo "Using existing hardware config: $HARDWARE"
elif [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo "Copying hardware config from /etc/nixos/hardware-configuration.nix..."
  mkdir -p "$(dirname "$HARDWARE")"
  cp /etc/nixos/hardware-configuration.nix "$HARDWARE"
  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$HARDWARE"
  fi
else
  echo "Generating hardware config..."
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

echo "Building system: nixos-rebuild switch --flake .#$HOST"
nixos-rebuild switch --flake ".#$HOST" --accept-flake-config
