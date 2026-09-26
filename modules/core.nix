{ lib, pkgs, ... }:
let
  manifest = import ../manifest.nix;
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = lib.mkBefore [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  networking.hostName = manifest.hostname;
  networking.networkmanager.enable = manifest.networkManager;

  time.timeZone = manifest.timezone;
  i18n.defaultLocale = manifest.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = manifest.locale;
    LC_IDENTIFICATION = manifest.locale;
    LC_MEASUREMENT = manifest.locale;
    LC_MONETARY = manifest.locale;
    LC_NAME = manifest.locale;
    LC_NUMERIC = manifest.locale;
    LC_PAPER = manifest.locale;
    LC_TELEPHONE = manifest.locale;
    LC_TIME = manifest.locale;
  };

  programs.dconf.enable = true;
  programs.fish.enable = true;

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
