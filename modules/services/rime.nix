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

        settings = {
          globalOptions.Hotkey = {
            "Activate IM" = "Control+space";
            "Enumerate IM" = "Control+Shift+space";
          };

          inputMethod = {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "rime";
            };
            "Groups/0/Items/0" = {
              Name = "keyboard-us";
              Layout = "";
            };
            "Groups/0/Items/1" = {
              Name = "rime";
              Layout = "";
            };
            GroupOrder = {
              "0" = "Default";
            };
          };
        };
      };
    };

  };
}
