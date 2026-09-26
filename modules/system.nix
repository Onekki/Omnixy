{ config, lib, ... }:
let
  manifest = import ../config/omnixy.nix;
  system = manifest.system;
  locale = system.locale;
  mirror = system.mirror;
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = lib.mkIf (mirror == "china") (lib.mkBefore [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ]);

  networking.hostName = system.hostname;
  networking.networkmanager.enable = system.networkManager;
  time.timeZone = system.timezone;
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
