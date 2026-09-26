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
  echo "生成 config/omnixy.nix（模板：config/omnixy.nix.template）..."
  mkdir -p "$(dirname "$OMNIXY_CONFIG")"
  cp "$ROOT/config/omnixy.nix.template" "$OMNIXY_CONFIG"

  DEFAULT_HOSTNAME="${OMNIXY_HOSTNAME:-$(hostnamectl --static 2>/dev/null || true)}"
  [ -n "$DEFAULT_HOSTNAME" ] || DEFAULT_HOSTNAME="omnixy"
  DEFAULT_USER="${OMNIXY_USER:-${SUDO_USER:-user}}"
  DEFAULT_TIMEZONE="${OMNIXY_TIMEZONE:-$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')}"
  [ -n "$DEFAULT_TIMEZONE" ] || DEFAULT_TIMEZONE="UTC"
  DEFAULT_LOCALE="${OMNIXY_LOCALE:-en_US.UTF-8}"

  sed -i \
    -e "s|@HOSTNAME@|$DEFAULT_HOSTNAME|g" \
    -e "s|@USERNAME@|$DEFAULT_USER|g" \
    -e "s|@FULLNAME@|$DEFAULT_USER|g" \
    -e "s|@TIMEZONE@|$DEFAULT_TIMEZONE|g" \
    -e "s|@LOCALE@|$DEFAULT_LOCALE|g" \
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
  cat <<'EOF'
还没有真实硬件配置。请先在已安装好的 NixOS 系统里运行：

  sudo nixos-generate-config
  

然后重新执行

  sudo bash scripts/bootstrap.sh

脚本会把 /etc/nixos/hardware-configuration.nix 自动复制到
hosts/<hostname>/hardware-configuration.nix，且不会提交到 git。
EOF
  exit 1
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
