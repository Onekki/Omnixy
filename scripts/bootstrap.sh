#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-omnixy}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARDWARE="$ROOT/hosts/$HOST/hardware-configuration.nix"

if [ "$EUID" -ne 0 ]; then
  echo "请用 sudo 运行：sudo bash scripts/bootstrap.sh"
  exit 1
fi

if [ ! -f "$ROOT/flake.nix" ]; then
  echo "没有找到 flake.nix，请确认在 Omnixy 仓库根目录执行。"
  exit 1
fi

OMNIXY_CONFIG="$ROOT/config/omnixy.nix"
if [ ! -f "$OMNIXY_CONFIG" ]; then
  echo "生成 config/omnixy.nix..."
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
    read -r -p "主机名 [$DEFAULT_HOSTNAME]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_HOSTNAME="$INPUT"
    read -r -p "用户名 [$DEFAULT_USER]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_USER="$INPUT"
    read -r -p "时区 [$DEFAULT_TIMEZONE]: " INPUT
    [ -n "$INPUT" ] && DEFAULT_TIMEZONE="$INPUT"
    read -r -p "软件源镜像 (china/global) [$DEFAULT_MIRROR]: " INPUT
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

if [ -f "$HARDWARE" ] && ! grep -q "请替换这个文件" "$HARDWARE"; then
  echo "检测到已有硬件配置：$HARDWARE"
elif [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo "从 /etc/nixos/hardware-configuration.nix 复制真实硬件配置..."
  mkdir -p "$(dirname "$HARDWARE")"
  cp /etc/nixos/hardware-configuration.nix "$HARDWARE"
  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$HARDWARE"
  fi
else
  echo "生成硬件配置..."
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
  echo "首次构建，先生成 flake.lock..."
  nix flake update
  if [ -n "${SUDO_USER:-}" ]; then
    chown "$SUDO_USER" "$ROOT/flake.lock"
  fi
fi

echo "开始构建系统：nixos-rebuild switch --flake .#$HOST"
nixos-rebuild switch --flake ".#$HOST" --accept-flake-config
