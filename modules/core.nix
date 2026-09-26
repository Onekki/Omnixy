{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "core" (manifest.enabledModules or [ ]);
in
{
  config = lib.mkIf enabled {
    environment.systemPackages = with pkgs; [
      bat
      btop
      curl
      fd
      git
      jq
      kitty
      neovim
      ripgrep
      unzip
    ];

    programs.dconf.enable = true;
    programs.fish.enable = true;
    programs.starship.enable = true;

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
  };
}
