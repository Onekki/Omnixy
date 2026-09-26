{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "rime" manifest.enabledModules;
in
{
  config = lib.mkIf enabled {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = [ pkgs.fcitx5-rime ];
        # Denial is Wayland-native; use the Wayland text-input frontend.
        waylandFrontend = true;
      };
    };

  };
}
