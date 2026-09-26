{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "core" manifest.enabledModules;
in
{
  config = lib.mkIf enabled {
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
  };
}
