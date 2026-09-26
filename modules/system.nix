{ config, lib, ... }:
let
  manifest = import ../config/omnixy.nix;
  system = manifest.system or { };
  locale = system.locale or "en_US.UTF-8";
  mirror = system.mirror or "global";
in
{
  nix.settings.substituters = lib.mkIf (mirror == "china") (lib.mkBefore [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ]);

  networking.hostName = system.hostname or "omnixy";
  networking.networkmanager.enable = system.networkManager or true;
  time.timeZone = system.timezone or "Asia/Shanghai";
  i18n.defaultLocale = locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
  };
}
