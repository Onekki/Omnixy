{ config, lib, ... }:
let
  manifest = import ../config/omnixy.nix;
  enabled = builtins.elem "denial" manifest.enabledModules;
  denial = manifest.settings.denial;
  displayManager = denial.displayManager;
  autologin = denial.autologin;
  userName = manifest.user.name;
in
{
  config = lib.mkMerge [
    (lib.mkIf enabled {
      programs.denial = {
        enable = true;
        ddc.enable = true;
        polkitAgent.enable = true;
      };

      hardware.graphics.enable = true;
    })

    (lib.mkIf (
      enabled && (displayManager == "gdm" || displayManager == "sddm")
    ) {
      services.xserver.enable = true;

      services.displayManager = {
        defaultSession = "denial";
        sddm.enable = displayManager == "sddm";
        gdm.enable = displayManager == "gdm";
        autoLogin = lib.mkIf autologin {
          enable = true;
          user = userName;
        };
      };
    })

    (lib.mkIf (enabled && displayManager == "greetd") {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${config.programs.denial.package}/bin/denial-session --start-locked";
            user = userName;
          };
        };
      };
    })
  ];
}
