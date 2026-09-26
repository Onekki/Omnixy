{ config, lib, pkgs, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "rime" (manifest.enabledModules or [ ]);
  rime = manifest.settings.rime or { };
  overwrite = rime.overwrite or false;
  user = (manifest.user or { }).name or "omnixy";
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

    environment.etc."omnixy/rime/default.custom.yaml".source =
      ../config/rime/default.custom.yaml;
    environment.etc."omnixy/rime/luna_pinyin_simp.custom.yaml".source =
      ../config/rime/luna_pinyin_simp.custom.yaml;

    system.activationScripts.omnixy-rime = {
      text = ''
        user=${lib.escapeShellArg user}
        dir="/home/$user/.local/share/fcitx5/rime"
        overwrite=${if overwrite then "1" else "0"}

        install -d -o "$user" -g users -m 0755 "$dir"

        install_rime_file() {
          if [ "$overwrite" = "1" ] || [ ! -e "$dir/$1" ]; then
            install -o "$user" -g users -m 0644 "/etc/omnixy/rime/$1" "$dir/$1"
          fi
        }

        install_rime_file default.custom.yaml
        install_rime_file luna_pinyin_simp.custom.yaml
      '';
      deps = [ "users" ];
    };
  };
}
