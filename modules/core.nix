{ lib, pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = lib.mkBefore [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  networking.hostName = "omnixy";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs.dconf.enable = true;

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
